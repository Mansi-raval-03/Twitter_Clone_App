import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Reactive list for UI if needed
  final RxList<TweetModel> tweets = <TweetModel>[].obs;

  // Stream of tweets (use directly in UI or bind to tweets)
  Stream<List<TweetModel>> tweetsStream() {
    return _firestore
        .collection('tweets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TweetModel.fromDoc(d)).toList());
  }

  Future<String> _uploadImage(File file) async {
    final ref =
        _storage.ref().child('tweets/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final upload = await ref.putFile(file);
    return await upload.ref.getDownloadURL();
  }

  Future<void> postTweet({
    required String content,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String imageUrl = '';
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile);
    }

    final tweetData = {
      'uid': user.uid,
      'username': user.displayName ?? 'User',
      'handle': '@${user.email?.split('@')[0] ?? 'user'}',
      'content': content,
      'likes': <String>[],
      'comments': <Map<String, dynamic>>[],
      'profileImage': user.photoURL ??
          'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('tweets').add(tweetData);
  }

  Future<void> toggleLike(String tweetId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('tweets').doc(tweetId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final List likes = (data['likes'] as List?) ?? [];
      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }
      tx.update(docRef, {'likes': likes});
    });
  }

  Future<void> deleteTweet(String tweetId) async {
    final docRef = _firestore.collection('tweets').doc(tweetId);
    await docRef.delete();
  }

  @override
  void onClose() {
    // cleanup if needed
    super.onClose();
  }
}
