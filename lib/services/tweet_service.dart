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
      'profileImage': 'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
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

    if (likes.contains(uid)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
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
      'profileImage': user.photoURL ?? 'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
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
    final doc = await ref.get();
    final data = doc.data() as Map<String, dynamic>;
    final retweets = List<String>.from(data['retweets'] ?? []);

    if (retweets.contains(uid)) {
      await ref.update({
        'retweets': FieldValue.arrayRemove([uid]),
        'retweetsCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'retweets': FieldValue.arrayUnion([uid]),
        'retweetsCount': FieldValue.increment(1),
      });
    }
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
