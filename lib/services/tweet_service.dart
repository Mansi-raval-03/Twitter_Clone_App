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
}
