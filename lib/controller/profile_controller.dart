import 'dart:async';
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

  // Load current authenticated user's profile
  Future<void> loadCurrentUser() async {
    isLoading.value = true;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      isLoading.value = false;
      return;
    }

    // Fetch user document from Firestore 
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

        // Manually map fields
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
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().asBroadcastStream();
  }

  Stream<List<TweetModel>> userTweetsStream(String uid) {
    final q = FirebaseFirestore.instance
        .collection('tweets')
        .where('uid', isEqualTo: uid)
        .limit(100);

    return q.snapshots().map((snap) {
      final tweets = snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
      tweets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tweets;
    }).asBroadcastStream();
  }

  Stream<List<TweetModel>> userRepliesStream(String uid) {
    // Instead of using collectionGroup which requires index,
    // we'll fetch tweets where user has replied by checking replies subcollection
    // For now, return empty stream to avoid index error
    // Can be enhanced by querying user's reply activity from a different structure
    return Stream.value(<TweetModel>[]).asBroadcastStream();
  }

  Stream<List<TweetModel>> userLikedTweetsStream(String uid) {
    final q = FirebaseFirestore.instance
        .collection('tweets')
        .where('likes', arrayContains: uid)
        .limit(100);

    return q.snapshots().map((snap) {
      final tweets = snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
      tweets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tweets;
    }).asBroadcastStream();
  }

  Stream<List<TweetModel>> userRetweetedTweetsStream(String uid) {
    final q = FirebaseFirestore.instance
        .collection('tweets')
        .where('retweets', arrayContains: uid)
        .limit(100);

    return q.snapshots().map((snap) {
      final tweets = snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
      tweets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tweets;
    }).asBroadcastStream();
  }

  /// Combined feed for profile: tweets, liked, retweeted, replies (parent tweets)
  Stream<List<TweetModel>> userUnifiedFeedStream(String uid) {
    final controller = StreamController<List<TweetModel>>.broadcast();

    List<TweetModel> tweets = [];
    List<TweetModel> liked = [];
    List<TweetModel> retweeted = [];
    List<TweetModel> replied = [];

    void emit() {
      final map = <String, TweetModel>{};
      for (final t in tweets) map[t.id] = t;
      for (final t in liked) map[t.id] = t;
      for (final t in retweeted) map[t.id] = t;
      for (final t in replied) map[t.id] = t;
      final list = map.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(list);
    }

    final sub1 = userTweetsStream(uid).listen((v) { tweets = v; emit(); }, onError: controller.addError);
    final sub2 = userLikedTweetsStream(uid).listen((v) { liked = v; emit(); }, onError: controller.addError);
    final sub3 = userRetweetedTweetsStream(uid).listen((v) { retweeted = v; emit(); }, onError: controller.addError);
    final sub4 = userRepliesStream(uid).listen((v) { replied = v; emit(); }, onError: controller.addError);

    controller.onCancel = () async {
      await sub1.cancel();
      await sub2.cancel();
      await sub3.cancel();
      await sub4.cancel();
    };

    return controller.stream;
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
