import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile user;
  final List<TweetModel> tweets;
  final List<TweetModel> replies;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.tweets,
    required this.replies,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs: Tweets, Replies, Media, Likes
  }

  @override
  Widget build(BuildContext context) {
    final joinedDate = 'Joined March 2020';
    final isVerified = widget.user.followers > 100; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            expandedHeight: 260,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {},
              ),
            ],
            flexibleSpace: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget.user.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black26],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: _buildProfilePicture(),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(),
                  const SizedBox(height: 12),
                  _buildProfileHeader(isVerified),
                  const SizedBox(height: 12),
                  _buildUserMeta(joinedDate),
                  const SizedBox(height: 12),
                  _buildUserStats(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Tweets'),
                Tab(text: 'Replies'),
                Tab(text: 'Media'),
                Tab(text: 'Likes'),
              ],
            ),
          ),

         SliverFillRemaining(
  child: TabBarView(
    controller: _tabController,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _buildTweetsList(),
      _buildTweetReplies(),
      _buildMediaGrid(),
      _buildTweetsList(),
    ],
  ),
),


        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
     child: CircleAvatar(
  radius: 48,
  backgroundImage: NetworkImage(widget.user.profileImage),
  backgroundColor: Colors.grey.shade200,
),

    );
  }

 Widget _buildHeaderRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      OutlinedButton(
        onPressed: () {
          Get.to(ProfileScreen(user: widget.user, tweets: widget.tweets, replies: widget.replies));
        },
        child: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontSize: 16)),
      ),
    ],
  );
}


  Widget _buildProfileHeader(bool isVerified) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
            ),
            const SizedBox(width: 6),
            if (isVerified) const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 20),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '@${widget.user.username}',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Text(
          widget.user.bio,
          style: const TextStyle(fontSize: 15, height: 1.35, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildUserMeta(String joinedDate) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (widget.user.location.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(widget.user.location, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(joinedDate, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    return Row(
      children: [
        _buildStatItem("Followers", widget.user.followers.toString()),
        const SizedBox(width: 16),
        _buildStatItem("Following", widget.user.following.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Row(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTweetsList() {
  return ListView.separated(
    key: const PageStorageKey('tweets'),
    itemCount: widget.tweets.length,
    padding: EdgeInsets.zero,
    separatorBuilder: (_, __) =>
        Divider(height: 1, color: Colors.grey.shade200),
    itemBuilder: (context, index) =>
        TweetCardWidget(tweet: widget.tweets[index]),
  );
}


 Widget _buildTweetReplies() {
  return ListView.separated(
    key: const PageStorageKey('replies'),
    itemCount: widget.replies.length,
    padding: EdgeInsets.zero,
    separatorBuilder: (_, __) =>
        Divider(height: 1, color: Colors.grey.shade200),
    itemBuilder: (context, index) {
      final reply = widget.replies[index];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Replying to ${reply.handle}',
              style: const TextStyle(color: Colors.lightBlueAccent),
            ),
          ),
          TweetCardWidget(tweet: reply),
        ],
      );
    },
  );
}


  Widget _buildMediaGrid() {
  final mediaTweets =
      widget.tweets.where((t) => t.imageUrl != null && t.imageUrl!.isNotEmpty).toList();

  if (mediaTweets.isEmpty) {
    return Center(
      child: Text('No media yet', style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  return GridView.builder(
    key: const PageStorageKey('media'),
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemCount: mediaTweets.length,
    itemBuilder: (context, index) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          mediaTweets[index].imageUrl!,
          fit: BoxFit.cover,
        ),
      );
    },
  );
}


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
