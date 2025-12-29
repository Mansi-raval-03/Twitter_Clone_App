
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/edit_profile.dart';
import 'package:twitter_clone_app/Pages/follow_list_page.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';
import 'package:twitter_clone_app/controller/tab_controller.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';

class ProfileScreen extends StatefulWidget {
  final String? viewedUserId; // if null, show current signed-in user
  const ProfileScreen({super.key, this.viewedUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
{
  
  final ProfileController _profileCtrl = Get.put(ProfileController());

 
  String? get _effectiveUid {
    if (widget.viewedUserId != null && widget.viewedUserId!.isNotEmpty) {
      return widget.viewedUserId;
    }
    return FirebaseAuth.instance.currentUser?.uid;
  }

  
  Widget _buildHeader(Map<String, dynamic>? data, String uid) {
    var name = data?['name'] ?? _profileCtrl.userProfile.value?.name ?? 'User';
    final username = data?['username'] ?? _profileCtrl.userProfile.value?.username ?? '';
    final bio = data?['bio'] ?? '';
    final location = data?['location'] ?? '';
    final joiningDateTimestamp = data?['createdAt'] as Timestamp?;
    final joiningDate = joiningDateTimestamp?.toDate() ?? DateTime.now();
    final profileImage = (data?['profileImage'] ?? data?['profilePicture'] ?? _profileCtrl.userProfile.value?.profileImage ?? '').toString();
    final coverImage = data?['coverImage'] ?? _profileCtrl.userProfile.value?.coverImage ?? '';
    final followers = (data?['followers'] ?? _profileCtrl.userProfile.value?.followers ?? 0).toString();
    final following = (data?['following'] ?? _profileCtrl.userProfile.value?.following ?? 0).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        SizedBox(
          height: Get.height * 0.2,
          width: Get.width,
          child: coverImage.isNotEmpty ? _buildCoverWidget(coverImage) : Container(color: Colors.grey.shade300),
        ),

        // Avatar and Edit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -20),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).shadowColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                      child: _buildAvatarWidget(profileImage),
                  ),
                ),
              ),
              const Spacer(),
              if (FirebaseAuth.instance.currentUser?.uid == uid)
                OutlinedButton(
                  onPressed: () async {
                    final res = await Get.to(() => EditProfilePage(username: '', bio: '', profileImageUrl: ''));
                    if (res is Map) setState(() {});
                  },
                  child: const Text('Edit Profile'),
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
              Text('@$username', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 8),
              if (bio.isNotEmpty) Text(bio),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('📍 $location'),
              const SizedBox(width: 12),
              Text('    Joined ${joiningDate.toLocal().toString().substring(0, 7)}'),
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


  Widget _buildCoverWidget(String coverPath) {
    // If it's an http or data URI use the resolver; otherwise try to resolve via Firebase Storage
    final trimmed = coverPath.trim();
    if (trimmed.isEmpty) return Container(color: Theme.of(context).dividerColor);

    if (trimmed.startsWith('http') || trimmed.startsWith('data:')) {
      final provider = resolveImageProvider(trimmed);
      if (provider == null) return Container(color: Theme.of(context).dividerColor);
      return Image(image: provider, fit: BoxFit.cover, width: double.infinity);
    }

    return FutureBuilder<String?>(future: _profileCtrl.resolveImageUrl(coverPath), builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return Container(color: context.theme.dividerColor);
      final url = snap.data;
      if (url == null || url.isEmpty) return Container(color: Theme.of(context).dividerColor);
      final provider = resolveImageProvider(url);
      if (provider == null) return Container(color: Theme.of(context).dividerColor);
      return Image(image: provider, fit: BoxFit.cover, width: double.infinity);
    });
  }

  Widget _buildAvatarWidget(String profilePath) {
    final trimmed = profilePath.trim();
    if (trimmed.isEmpty) return const CircleAvatar(radius: 48, child: Icon(Icons.person_outline, size: 40));

    // If http or data URI, use resolver directly
    if (trimmed.startsWith('http') || trimmed.startsWith('data:')) {
      final provider = resolveImageProvider(trimmed);
      if (provider == null) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
      return CircleAvatar(radius: 48, backgroundImage: provider);
    }

    // Otherwise try to resolve via Firebase Storage
    return FutureBuilder<String?>(
      future: _profileCtrl.resolveImageUrl(profilePath),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(radius: 48, backgroundImage: AssetImage('assets/placeholder.png'));
        }
        final url = snap.data;
        if (url == null || url.isEmpty) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
        final provider = resolveImageProvider(url);
        if (provider == null) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
        return CircleAvatar(radius: 48, backgroundImage: provider);
      },
    );
  }

  TabBar _buildTabBar(TabController controller) {
    final labels = ['Tweets', 'Replies', 'Retweets', 'Likes'];
    final tabs = List<Widget>.generate(controller.length, (i) {
      final text = i < labels.length ? labels[i] : '';
      return Tab(text: text);
    });

    return TabBar(
      controller: controller,
      labelColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).textTheme.bodyLarge?.color ??  Colors.black,
      tabs: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _effectiveUid;
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Theme.of(context).iconTheme.color),
              SizedBox(height: 16),
              Text('No signed in user', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text(
                'Please sign in to view your profile',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: AppBar(
        
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile',style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
        titleTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileCtrl.userDocStream(uid).asBroadcastStream(),
        builder: (context, snapshot) {
          // Handle errors
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).iconTheme.color),
                  SizedBox(height: 16),
                  Text('Error loading profile', style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            );
          }

          // Handle user not found
          if (snapshot.hasData && !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Theme.of(context).iconTheme.color),
                  SizedBox(height: 16),
                  Text('Profile not found', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Your profile needs to be set up',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data?.data();
          ProfileTabController tabControllerCtrl;
          try {
            tabControllerCtrl = Get.find<ProfileTabController>();
          } catch (_) {
            tabControllerCtrl = Get.put(ProfileTabController());
          }
          final tabCtrl = tabControllerCtrl.tabController;
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader(data, uid)),
              SliverPersistentHeader(pinned: true, delegate: _TabBarDelegate(_buildTabBar(tabCtrl))),
            ],
            body: TabBarView(controller: tabCtrl, children: List<Widget>.generate(tabCtrl.length, (index) {
              switch (index) {
                case 0:
                  return StreamBuilder<List<TweetModel>>(
                    stream: _profileCtrl.userTweetsStream(uid).asBroadcastStream(),
                    builder: (c, s) {
                      if (s.hasError) return Center(child: Text('Error loading tweets: ${s.error}'));
                      if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final raw = s.data ?? [];
                      final profileImageFromUser = (data?['profileImage'] ?? data?['profilePicture'] ?? '').toString();
                      final tweets = raw.map((t) {
                        final img = profileImageFromUser.isNotEmpty ? profileImageFromUser : t.profileImage;
                        return TweetModel(
                          id: t.id,
                          uid: t.uid,
                          username: t.username,
                          handle: t.handle,
                          profileImage: img,
                          content: t.content,
                          imageUrl: t.imageUrl,
                          likes: t.likes,
                          comments: t.comments,
                          createdAt: t.createdAt,
                          isLiked: t.isLiked,
                        );
                      }).toList();

                      if (tweets.isEmpty) return const Center(child: Text('No tweets'));

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: tweets.length,
                        separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (_, i) => TweetCardWidget(tweet: tweets[i]),
                      );
                    },
                  );
                case 1:
                  return StreamBuilder<List<TweetModel>>(
                    stream: _profileCtrl.userRepliesStream(uid).asBroadcastStream(),
                    builder: (c, s) {
                      if (s.hasError) return Center(child: Text('Error loading replies: ${s.error}'));
                      if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final raw = s.data ?? [];
                      final profileImageFromUser = (data?['profileImage'] ?? data?['profilePicture'] ?? '').toString();
                      final replies = raw.map((r) {
                        final img = profileImageFromUser.isNotEmpty ? profileImageFromUser : r.profileImage;
                        return TweetModel(
                          id: r.id,
                          uid: r.uid,
                          username: r.username,
                          handle: r.handle,
                          profileImage: img,
                          content: r.content,
                          imageUrl: r.imageUrl,
                          likes: r.likes,
                          comments: r.comments,
                          createdAt: r.createdAt,
                          isLiked: r.isLiked,
                        );
                      }).toList();

                      if (replies.isEmpty) return const Center(child: Text('No replies'));
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: replies.length,
                        separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (_, i) => TweetCardWidget(tweet: replies[i]),
                      );
                    },
                  );
                case 2:
                  // Retweets tab
                  return StreamBuilder<List<TweetModel>>(
                    stream: _profileCtrl.userRetweetedTweetsStream(uid).asBroadcastStream(),
                    builder: (c, s) {
                      if (s.hasError) return Center(child: Text('Error loading media: ${s.error}'));
                      if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final raw = s.data ?? [];
                      (data?['profileImage'] ?? data?['profilePicture'] ?? '').toString();
                      // For retweets we should show the original author's profile image
                      // (do NOT replace with the profile being viewed). Keep the
                      // tweet's `profileImage` so retweets/likes reflect original author.
                      final retweets = raw.map((t) {
                        return TweetModel(
                          id: t.id,
                          uid: t.uid,
                          username: t.username,
                          handle: t.handle,
                          profileImage: t.profileImage,
                          content: t.content,
                          imageUrl: t.imageUrl,
                          likes: t.likes,
                          comments: t.comments,
                          createdAt: t.createdAt,
                          isLiked: t.isLiked,
                        );
                      }).toList();

                      if (retweets.isEmpty) return const Center(child: Text('No retweets'));
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: retweets.length,
                        separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (_, i) => TweetCardWidget(tweet: retweets[i]),
                      );
                    },
                  );
               
                case 3:
                  // Likes tab
                  return StreamBuilder<List<TweetModel>>(
                    stream: _profileCtrl.userLikedTweetsStream(uid).asBroadcastStream(),
                    builder: (c, s) {
                      if (s.hasError) return Center(child: Text('Error loading likes: ${s.error}'));
                      if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final raw = s.data ?? [];
                      (data?['profileImage'] ?? data?['profilePicture'] ?? '').toString();
                      // For liked tweets, show the original author's profile image
                      // rather than the profile owner's image.
                      final tweets = raw.map((t) {
                        return TweetModel(
                          id: t.id,
                          uid: t.uid,
                          username: t.username,
                          handle: t.handle,
                          profileImage: t.profileImage,
                          content: t.content,
                          imageUrl: t.imageUrl,
                          likes: t.likes,
                          comments: t.comments,
                          createdAt: t.createdAt,
                          isLiked: t.isLiked,
                        );
                      }).toList();

                      if (tweets.isEmpty) return const Center(child: Text('No liked tweets'));
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: tweets.length,
                        separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                        itemBuilder: (_, i) => TweetCardWidget(tweet: tweets[i]),
                      );
                    },
                  );
                default:
                  return const Center(child: SizedBox.shrink());
              }
            })),
          );
        },
      ),
    );
  }

  // TabController is provided by `ProfileTabController` (app-level). No local controller lifecycle here.
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
