import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TweetService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Create Tweet
  static Future<void> createTweet(String content) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore.collection('tweets').add({
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
  }

  /// Like / Unlike Tweet (REAL-TIME)
  static Future<void> toggleLike(String tweetId, List likes) async {
    final uid = _auth.currentUser!.uid;
    final ref = _firestore.collection('tweets').doc(tweetId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final current = List<String>.from(data['likes'] ?? []);
      if (current.contains(uid)) {
        tx.update(ref, {'likes': FieldValue.arrayRemove([uid])});
      } else {
        tx.update(ref, {'likes': FieldValue.arrayUnion([uid])});
      }
    });
  }

  /// Add Reply/Comment to Tweet
  static Future<void> addReply(String tweetId, String replyContent) async {
    final user = _auth.currentUser;
    if (user == null) return;

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
          'originalCreatedAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        };

        // Create a new tweet document representing the retweet
        final retweetDoc = {
          'uid': currentUser.uid,
          'username': currentUser.displayName ?? 'User',
          'handle': currentUser.email != null ? '@${currentUser.email!.split('@')[0]}' : '@user',
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
