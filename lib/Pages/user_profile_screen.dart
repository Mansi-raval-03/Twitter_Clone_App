
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/edit_profile.dart';
import 'package:twitter_clone_app/Pages/follow_list_page.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';
import 'package:twitter_clone_app/services/database_services.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';

class UserProfileScreen extends StatefulWidget {
  final String? viewedUserId; // if null, show current signed-in user
   UserProfileScreen({super.key, this.viewedUserId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  
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
          height: 250,
          width: double.infinity,
          child: coverImage.isNotEmpty ? _buildCoverWidget(coverImage) : Container(color: Theme.of(context).dividerColor),
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
                      border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                      child: _buildAvatarWidget(profileImage),
                  ),
                ),
              ),
              SizedBox(height: Get.height * 0.1),
              const Spacer(
                flex: 1,
              ),
                SizedBox(height: Get.height * 0.1),
              Builder(builder: (context) {
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                if (currentUid == uid) {
                  return OutlinedButton(
                    onPressed: () async {
                      final res = await Get.to(() => EditProfilePage(username: '', bio: '', profileImageUrl: ''));
                      if (res is Map) setState(() {});
                    },
                    child: const Text('Edit Profile'),
                  );
                }

                if (currentUid == null) return const SizedBox.shrink();

                return FutureBuilder<bool>(
                  future: DatabaseServices.isFollowing(currentUid, uid),
                  builder: (c, s) {
                    final following = s.data ?? false;
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: following ? Theme.of(context).dividerColor : null,
                        foregroundColor: following ? Theme.of(context).textTheme.bodyLarge?.color : null,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      onPressed: () async {
                        if (following) {
                          await DatabaseServices.unfollowUser(currentUid, uid);
                        } else {
                          final curData = _profileCtrl.userProfile.value;
                          final curMap = {
                            'uid': curData?.uid ?? currentUid,
                            'username': curData?.username ?? '',
                            'name': curData?.name ?? '',
                            'profileImage': curData?.profileImage ?? '',
                          };
                          final targetMap = {
                            'uid': uid,
                            'username': (data?['username'] ?? '')?.toString() ?? '',
                            'name': (data?['name'] ?? '')?.toString() ?? '',
                            'profileImage': (data?['profileImage'] ?? data?['profilePicture'] ?? '')?.toString() ?? '',
                          };
                          await DatabaseServices.followUser(currentUid, curMap, uid, targetMap);
                        }
                        setState(() {});
                      },
                      child: Text(following ? 'Following' : 'Follow'),
                    );
                  },
                );
              }),
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

  @override
  Widget build(BuildContext context) {
    final uid = _effectiveUid;
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Text(
            widget.viewedUserId != null 
              ? 'User not found' 
              : 'No signed in user',
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile',style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),),
        titleTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        leading: BackButton(onPressed: () {
          Get.back();
        }),
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
                  Text('Error loading profile', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(color: Colors.grey),
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
                children: const [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('User profile not found', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'This user may not have completed their profile setup',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data?.data();
          final profileImageFromUser = (data?['profileImage'] ?? data?['profilePicture'] ?? '').toString();

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader(data, uid)),
            ],
            body: StreamBuilder<List<TweetModel>>(
              stream: _profileCtrl.userUnifiedFeedStream(uid),
              builder: (c, s) {
                if (s.hasError) {
                  return CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('Error loading feed: ${s.error}')),
                      ),
                    ],
                  );
                }
                if (s.connectionState == ConnectionState.waiting) {
                  return const CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }
                final raw = s.data ?? [];
                final items = raw.map((t) {
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

                if (items.isEmpty) {
                  return const CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('No activity yet')),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                  itemBuilder: (_, i) => TweetCardWidget(tweet: items[i]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
