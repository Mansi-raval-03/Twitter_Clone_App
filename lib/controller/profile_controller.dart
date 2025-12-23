import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
        int toInt(dynamic v) {
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
          posts: toInt(data['posts']),
          followers: toInt(data['followers']),
          following: toInt(data['following']),
          likes: toInt(data['likes']),
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
        profileImage: firebaseUser.photoURL ?? '',
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

    final authUser = FirebaseAuth.instance.currentUser;
    final authUid = authUser?.uid.trim();
    if (authUid != null && authUid.isNotEmpty) return authUid;

    final profileVal = userProfile.value;
    final ctrlUid = profileVal?.uid.trim();
    if (ctrlUid != null && ctrlUid.isNotEmpty) return ctrlUid;

    return null;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<List<TweetModel>> userTweetsStream(String uid) {
    // Fetch all tweets ordered by createdAt and filter client-side by uid.
    return FirebaseFirestore.instance
        .collection('tweets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      try {
        // ignore: avoid_print
        print('ProfileController.userTweetsStream(all) -> ${snap.docs.length} docs');
      } catch (_) {}
      final all = snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
      return all.where((t) => t.uid == uid).toList();
    });
  }

  Stream<List<TweetModel>> userRepliesStream(String uid) {
    // Fetch replies authored by `uid` and resolve their parent tweets.
    final repliesQuery = FirebaseFirestore.instance
        .collectionGroup('replies')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return repliesQuery.snapshots().asyncMap((snap) async {
      try {
        // ignore: avoid_print
        print('ProfileController.userRepliesStream(filtered) -> ${snap.docs.length} docs');
      } catch (_) {}

      // Collect parent tweet IDs
      final parentIds = <String>{};
      for (final doc in snap.docs) {
        final parent = doc.reference.parent.parent;
        if (parent != null) parentIds.add(parent.id);
      }

      // Fetch parent tweets in parallel
      final futures = parentIds.map((id) async {
        final doc = await FirebaseFirestore.instance.collection('tweets').doc(id).get();
        return doc.exists ? TweetModel.fromDoc(doc) : null;
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<TweetModel>().toList();
    });
  }

  Stream<List<TweetModel>> userLikedTweetsStream(String uid) {
    // Fetch all tweets ordered by createdAt and filter client-side by likes containing uid.
    return FirebaseFirestore.instance
        .collection('tweets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      try {
        // ignore: avoid_print
        print('ProfileController.userLikedTweetsStream(all) -> ${snap.docs.length} docs');
      } catch (_) {}
      final all = snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
      return all.where((t) => t.likes.contains(uid)).toList();
    });
  }

  Stream<List<TweetModel>> userRetweetedTweetsStream(String uid) {
    // Fetch all tweets ordered by createdAt and filter client-side by retweets containing uid.
    return FirebaseFirestore.instance
        .collection('tweets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      try {
        // ignore: avoid_print
        print('ProfileController.userRetweetedTweetsStream(all) -> ${snap.docs.length} docs');
      } catch (_) {}
      final all = snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
      return all.where((t) => t.retweets.contains(uid)).toList();
    });
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