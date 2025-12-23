
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:twitter_clone_app/Pages/edit_profile.dart';
import 'package:twitter_clone_app/Pages/follow_list_page.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';

/// Profile screen shows a user's profile and their tweets/replies/media/likes
/// Data is loaded from Firestore in real-time. If `viewedUserId` is null
/// the currently authenticated user is shown.
class ProfileScreen extends StatefulWidget {
  final String? viewedUserId; // if null, show current signed-in user
  const ProfileScreen({super.key, this.viewedUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  
  final ProfileController _profileCtrl = Get.put(ProfileController());

 

  String? get _effectiveUid {
    return _profileCtrl.effectiveUid(viewedUserId: widget.viewedUserId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _userTweetsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('tweets')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _userRepliesStream(String uid) {
    return FirebaseFirestore.instance
        .collectionGroup('replies')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _userLikedTweetsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('tweets')
        .where('likes', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<TweetModel> _mapTweetDocsToModels(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs.map((d) => TweetModel.fromDoc(d)).toList();
  }

  List<TweetModel> _mapRepliesToTweetModels(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs.map((d) {
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
    }).toList();
  }

  Widget _buildHeader(Map<String, dynamic>? data, String uid) {
    var name = data?['name'] ?? _profileCtrl.userProfile.value?.name ?? 'User';
    final username = data?['username'] ?? _profileCtrl.userProfile.value?.username ?? '';
    final bio = data?['bio'] ?? '';
    final location = data?['location'] ?? '';
    final joiningDateTimestamp = data?['createdAt'] as Timestamp?;
    final joiningDate = joiningDateTimestamp?.toDate() ?? DateTime.now();
    final profileImage = data?['profileImage'] ?? _profileCtrl.userProfile.value?.profileImage ?? '';
    final coverImage = data?['coverImage'] ?? _profileCtrl.userProfile.value?.coverImage ?? '';
    final followers = (data?['followers'] ?? _profileCtrl.userProfile.value?.followers ?? 0).toString();
    final following = (data?['following'] ?? _profileCtrl.userProfile.value?.following ?? 0).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        SizedBox(
          height: 250,
          width: double.infinity,
          child: coverImage.isNotEmpty ? _buildCoverWidget(coverImage) : Container(color: Colors.grey.shade200),
        ),

        // Avatar and Edit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                    child: _buildAvatarWidget(profileImage),
                ),
              ),
              SizedBox(width: 180),
              if (FirebaseAuth.instance.currentUser?.uid == uid)
                OutlinedButton(
                  onPressed: () async {
                    final res = await Get.to(() => EditProfilePage(username: '', bio: '', profileImageUrl: ''));
                    if (res is Map) setState(() {});
                  },
                  child: const Text('Edit'),
                ),
            ],
          ),
        ),


        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('@$username', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              if (bio.isNotEmpty) Text(bio),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('📍 $location'),
              const SizedBox(width: 12),
              Text(' ${joiningDate.toLocal().toString().substring(0, 7)}'),
            ],
          ),
          const SizedBox(height: 12),
             
              Row(children: [
                GestureDetector(
                  onTap: () {
                    Get.to(() => FollowListPage(userId: uid, showFollowers: true, title: 'Followers'));
                  },
                  child: Text('$followers followers', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Get.to(() => FollowListPage(userId: uid, showFollowers: false, title: 'Following'));
                  },
                  child: Text('$following following'),
                ),
              ]),
            ],
          ),
        ),

           
        const SizedBox(height: 12),
      ],
    );
  }

  Future<String?> _resolveImageUrl(String? path) async {
    return await _profileCtrl.resolveImageUrl(path);
  }

  Widget _buildCoverWidget(String coverPath) {
    // If it's an http url use it directly; otherwise try to resolve via Firebase Storage
    if (coverPath.trim().startsWith('http')) return Image.network(coverPath, fit: BoxFit.cover, width: double.infinity);

    return FutureBuilder<String?>(future: _profileCtrl.resolveImageUrl(coverPath), builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return Container(color: Colors.grey.shade200);
      final url = snap.data;
      if (url == null || url.isEmpty) return Container(color: Colors.grey.shade200);
      return Image.network(url, fit: BoxFit.cover, width: double.infinity);
    });
  }

  Widget _buildAvatarWidget(String profilePath) {
    if (profilePath.trim().isEmpty) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
    if (profilePath.trim().startsWith('http')) return CircleAvatar(radius: 48, backgroundImage: NetworkImage(profilePath));

    return FutureBuilder<String?>(future: _profileCtrl.resolveImageUrl(profilePath), builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const CircleAvatar(radius: 48);
      final url = snap.data;
      if (url == null || url.isEmpty) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
      return CircleAvatar(radius: 48, backgroundImage: NetworkImage(url));
    });
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: TabController(length: 4, vsync: this),
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.black,
      tabs: const [Tab(text: 'Tweets'), Tab(text: 'Replies'), Tab(text: 'Media'), Tab(text: 'Likes')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _effectiveUid;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('No signed in user')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: BackButton(onPressed: () {
          Get.to(MainNavigationScreen(user: '', tweets: [], replies: []));
        }),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileCtrl.userDocStream(uid),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader(data, uid)),
              SliverPersistentHeader(pinned: true, delegate: _TabBarDelegate(_buildTabBar())),
            ],
            body: TabBarView(controller: TabController(length: 4, vsync: this), children: [
              StreamBuilder<List<TweetModel>>(
                stream: _profileCtrl.userTweetsStream(uid),
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!s.hasData || s.data!.isEmpty) return const Center(child: Text('No tweets'));
                  final tweets = s.data!;
                  return ListView.separated(padding: const EdgeInsets.only(bottom: 80), itemCount: tweets.length, separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300), itemBuilder: (_, i) => TweetCardWidget(tweet: tweets[i]));
                },
              ),
              // Replies
              StreamBuilder<List<TweetModel>>(
                stream: _profileCtrl.userRepliesStream(uid),
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!s.hasData || s.data!.isEmpty) return const Center(child: Text('No replies'));
                  final replies = s.data!;
                  return ListView.separated(padding: const EdgeInsets.only(bottom: 80), itemCount: replies.length, separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300), itemBuilder: (_, i) => TweetCardWidget(tweet: replies[i]));
                },
              ),
              // Media
              StreamBuilder<List<TweetModel>>(
                stream: _profileCtrl.userMediaStream(uid),
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!s.hasData || s.data!.isEmpty) return const Center(child: Text('No media'));
                  final media = s.data!;
                  if (media.isEmpty) return const Center(child: Text('No media'));
                  return GridView.builder(padding: const EdgeInsets.all(12), itemCount: media.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6), itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(media[i].imageUrl, fit: BoxFit.cover)));
                },
              ),
              // Likes
              StreamBuilder<List<TweetModel>>(
                stream: _profileCtrl.userLikedTweetsStream(uid),
                builder: (c, s) {
                  if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!s.hasData || s.data!.isEmpty) return const Center(child: Text('No liked tweets'));
                  final tweets = s.data!;
                  return ListView.separated(padding: const EdgeInsets.only(bottom: 80), itemCount: tweets.length, separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300), itemBuilder: (_, i) => TweetCardWidget(tweet: tweets[i]));
                },
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
