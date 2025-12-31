import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twitter_clone_app/services/notification_service.dart';

class TweetService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Create Tweet
  static Future<void> createTweet(String content) async {
    final user = _auth.currentUser;

    if (user == null) return;

    final tweetRef = await _firestore.collection('tweets').add({
      'uid': user.uid,
      'username': user.displayName ?? 'User',
      'handle': user.email!.split('@')[0],
      'content': content,
      'profileImage': user.photoURL ?? '',
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'commentsCount': 0,
      'retweetsCount': 0,
    });

    // Extract mentions from content and send notifications
    await _processMentions(content, tweetRef.id);
  }

  /// Extract mentions (@username) from content and send notifications
  static Future<void> _processMentions(String content, String tweetId) async {
    final mentionRegex = RegExp(r'@(\w+)');
    final mentions = mentionRegex.allMatches(content);

    if (mentions.isEmpty) return;

    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    // Process each mention
    for (final match in mentions) {
      final username = match.group(1);
      if (username == null) continue;

      try {
        // Find user by username
        final usersQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (usersQuery.docs.isNotEmpty) {
          final mentionedUserId = usersQuery.docs.first.id;

          // Don't notify yourself
          if (mentionedUserId != currentUid) {
            await NotificationService.notifyMention(
              mentionedUserId: mentionedUserId,
              tweetId: tweetId,
              tweetContent: content,
            );
          }
        }
      } catch (e) {
        print('Error processing mention @$username: $e');
      }
    }
  }

  /// Like / Unlike Tweet (REAL-TIME)
  static Future<void> toggleLike(String tweetId, List likes) async {
    final uid = _auth.currentUser!.uid;
    final ref = _firestore.collection('tweets').doc(tweetId);

    bool isLiking = false;
    String? tweetOwnerId;
    String? tweetContent;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final current = List<String>.from(data['likes'] ?? []);

      // Store tweet info for notification
      tweetOwnerId = data['uid']?.toString();
      tweetContent = data['content']?.toString();

      if (current.contains(uid)) {
        tx.update(ref, {
          'likes': FieldValue.arrayRemove([uid]),
        });
        isLiking = false;
      } else {
        tx.update(ref, {
          'likes': FieldValue.arrayUnion([uid]),
        });
        isLiking = true;
      }
    });

    // Send notification if user liked the tweet (not unlike)
    if (isLiking && tweetOwnerId != null && tweetOwnerId != uid) {
      await NotificationService.notifyLike(
        tweetOwnerId: tweetOwnerId!,
        tweetId: tweetId,
        tweetContent: tweetContent,
      );
    }
  }

  /// Add Reply/Comment to Tweet
  static Future<void> addReply(String tweetId, String replyContent) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get tweet owner info for notification
    final tweetDoc = await _firestore.collection('tweets').doc(tweetId).get();
    final tweetData = tweetDoc.data() ?? {};
    final tweetOwnerId = tweetData['uid']?.toString();

    // Create a new reply document in a subcollection
    final replyRef = await _firestore
        .collection('tweets')
        .doc(tweetId)
        .collection('replies')
        .add({
          'uid': user.uid,
          'username': user.displayName ?? 'User',
          'handle': '@${user.email!.split('@')[0]}',
          'content': replyContent,
          'profileImage': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

    // Update the comments array with just the reply ID
    final tweetRef = _firestore.collection('tweets').doc(tweetId);
    await tweetRef.update({
      'comments': FieldValue.arrayUnion([replyRef.id]),
    });

    // Send notification to tweet owner
    if (tweetOwnerId != null && tweetOwnerId != user.uid) {
      await NotificationService.notifyReply(
        tweetOwnerId: tweetOwnerId,
        tweetId: tweetId,
        replyContent: replyContent,
      );
    }

    // Check for mentions in the reply
    await _processMentions(replyContent, tweetId);
  }

  /// Toggle Retweet
  static Future<void> toggleRetweet(String tweetId, String uid) async {
    final ref = _firestore.collection('tweets').doc(tweetId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final current = List<String>.from(data['retweets'] ?? []);

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      if (current.contains(uid)) {
        // Remove retweet: update original tweet counts and remove any retweet doc created by this user
        tx.update(ref, {
          'retweets': FieldValue.arrayRemove([uid]),
          'retweetsCount': FieldValue.increment(-1),
        });

        // Find retweet doc and delete it (there should be at most one)
        final q = await _firestore
            .collection('tweets')
            .where('isRetweet', isEqualTo: true)
            .where('originalTweetId', isEqualTo: tweetId)
            .where('uid', isEqualTo: uid)
            .get();

        for (var doc in q.docs) {
          tx.delete(doc.reference);
        }
      } else {
        // Add retweet: update original tweet and create a new retweet document
        tx.update(ref, {
          'retweets': FieldValue.arrayUnion([uid]),
          'retweetsCount': FieldValue.increment(1),
        });

        // Build embedded original data snapshot to store on retweet doc
        final originalMap = <String, dynamic>{
          'originalTweetId': tweetId,
          'originalUid': data['uid'] ?? '',
          'originalUsername': data['username'] ?? '',
          'originalHandle': data['handle'] ?? '',
          'originalProfileImage': data['profileImage'] ?? '',
          'originalContent': data['content'] ?? '',
          'originalImageUrl': data['imageUrl'] ?? '',
          'originalCreatedAt':
              data['createdAt'] ?? FieldValue.serverTimestamp(),
        };

        // Create a new tweet document representing the retweet
        final retweetDoc = {
          'uid': currentUser.uid,
          'username': currentUser.displayName ?? 'User',
          'handle': currentUser.email != null
              ? '@${currentUser.email!.split('@')[0]}'
              : '@user',
          'profileImage': currentUser.photoURL ?? '',
          'isRetweet': true,
          'original': originalMap,
          'originalTweetId': tweetId,
          // also mirror original content/image into the retweet doc for simpler UI rendering
          'content': (originalMap['originalContent'] ?? ''),
          'imageUrl': (originalMap['originalImageUrl'] ?? ''),
          'createdAt': FieldValue.serverTimestamp(),
          'likes': [],
          'commentsCount': 0,
          'retweetsCount': 0,
        };

        tx.set(_firestore.collection('tweets').doc(), retweetDoc);

        // Send notification to tweet owner (after transaction)
        final tweetOwnerId = data['uid']?.toString();
        final tweetContent = data['content']?.toString();
        if (tweetOwnerId != null && tweetOwnerId != uid) {
          // Schedule notification after transaction completes
          Future.delayed(Duration.zero, () {
            NotificationService.notifyRetweet(
              tweetOwnerId: tweetOwnerId,
              tweetId: tweetId,
              tweetContent: tweetContent,
            );
          });
        }
      }
    });
  }

  /// Get Replies for a Tweet (Real-time Stream)
  static Stream<QuerySnapshot> getRepliesStream(String tweetId) {
    return _firestore
        .collection('tweets')
        .doc(tweetId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Get Single Tweet (Real-time Stream)
  static Stream<DocumentSnapshot> getTweetStream(String tweetId) {
    return _firestore.collection('tweets').doc(tweetId).snapshots();
  }

  /// Delete Tweet
  static Future<void> deleteTweet(String tweetId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Delete all replies in the subcollection first
      final repliesSnapshot = await _firestore
          .collection('tweets')
          .doc(tweetId)
          .collection('replies')
          .get();

      for (var doc in repliesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the tweet document
      await _firestore.collection('tweets').doc(tweetId).delete();
    } catch (e) {
      throw Exception('Failed to delete tweet: $e');
    }
  }
}
