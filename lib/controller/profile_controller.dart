import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileController extends GetxController {
  final userProfile = Rxn<UserProfile>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    isLoading.value = true;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      isLoading.value = false;
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      try {
        userProfile.value = UserProfile.fromDoc(doc);
      } catch (_) {
        // fallback to minimal mapping if model parsing fails
        final data = doc.data()!;
        int _toInt(dynamic v) {
          if (v == null) return 0;
          if (v is int) return v;
          if (v is num) return v.toInt();
          final s = v.toString();
          return int.tryParse(s) ?? 0;
        }

        userProfile.value = UserProfile(
          uid: doc.id,
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          bio: data['bio'] ?? '',
          location: data['location'] ?? '',
          email: data['email'] ?? '',
          profileImage: data['profileImage'] ?? '',
          coverImage: data['coverImage'] ?? '',
          posts: _toInt(data['posts']),
          followers: _toInt(data['followers']),
          following: _toInt(data['following']),
          likes: _toInt(data['likes']),
        );
      }
    } else {
      // If user doc missing, create a minimal UserProfile from auth
      userProfile.value = UserProfile(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        username: firebaseUser.email?.split('@')[0] ?? '',
        bio: '',
        location: '',
        email: firebaseUser.email ?? '',
        profileImage: '',
        coverImage: '',
        posts: 0,
        followers: 0,
        following: 0,
        likes: 0,
      );
    }

    isLoading.value = false;
  }

  /// Determine an effective uid to display: prefer explicit `viewedUserId`,
  /// otherwise authenticated user, otherwise cached profile uid.
  String? effectiveUid({String? viewedUserId}) {
    final vId = viewedUserId?.toString().trim();
    if (vId != null && vId.isNotEmpty) return vId;

    final authUid = FirebaseAuth.instance.currentUser?.uid?.toString().trim();
    if (authUid != null && authUid.isNotEmpty) return authUid;

    final ctrlUid = userProfile.value?.uid?.toString().trim();
    if (ctrlUid != null && ctrlUid.isNotEmpty) return ctrlUid;

    return null;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<List<TweetModel>> userTweetsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('tweets')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TweetModel.fromDoc(d)).toList());
  }

  Stream<List<TweetModel>> userRepliesStream(String uid) {
    return FirebaseFirestore.instance
        .collectionGroup('replies')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return TweetModel(
                id: d.id,
                uid: data['uid']?.toString() ?? '',
                name: data['username'] ?? 'User',
                username: data['username'] ?? 'user',
                handle: data['handle'] ?? '@user',
                profileImage: data['profileImage'] ?? '',
                content: data['content'] ?? '',
                imageUrl: '',
                likes: List<String>.from(data['likes'] ?? []),
                comments: [],
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isLiked: false,
              );
            }).toList());
  }

  Stream<List<TweetModel>> userLikedTweetsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('tweets')
        .where('likes', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TweetModel.fromDoc(d)).toList());
  }

  /// Media stream derived from user tweets (only tweets with non-empty imageUrl)
  Stream<List<TweetModel>> userMediaStream(String uid) {
    return userTweetsStream(uid).map((list) => list.where((t) => t.imageUrl.isNotEmpty).toList());
  }

  /// Try to resolve a storage path to a download URL. Returns the input if already an http URL.
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> resolveImageUrl(String? path) async {
    if (path == null) return null;
    final trimmed = path.toString().trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;

    try {
      final ref = _storage.ref(trimmed);
      final url = await ref.getDownloadURL();
      return url;
    } catch (_) {
      return null;
    }
  }
}