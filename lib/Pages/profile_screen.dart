import 'package:flutter/material.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${widget.user.posts} posts',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
 

          /// Main top content
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCoverImage(),
                _buildProfileHeader(),
                _buildUserStats(),
              ],
            ),
          ),

          /// Tabs
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Replies'),
                Tab(text: 'Likes'),
              ],
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTweetsList(),
                _buildTweetReplies(),
                _buildTweetsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.network(widget.user.coverImage, fit: BoxFit.cover),

          ),
          Positioned(bottom: -40, left: 16, child: _buildProfilePicture()),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 4),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
  radius: 50,
  backgroundImage: NetworkImage(widget.user.profileImage),
),

    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 55, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${widget.user.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.bio,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(widget.user.location),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(widget.user.email),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _buildStatItem("Following", widget.user.following.toString()),
          _buildStatItem("Followers", widget.user.followers.toString()),
          _buildStatItem("Likes", widget.user.likes.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Expanded(
      child: Row(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTweetsList() {
    return ListView.separated(
      itemCount: widget.tweets.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final tweet = widget.tweets[index];
        return TweetCardWidget(tweet: tweet);
      },
    );
  }

Widget _buildTweetItem(String content) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey[850]!)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.user.profileImage),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('@${widget.user.username} · 2h',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(content),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildTweetReplies() {
    return ListView.separated(
      itemCount: widget.replies.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final reply = widget.replies[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

Widget _buildReplyItem(String content) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Replying to @princy",
            style: const TextStyle(color: Colors.blue)),
        const SizedBox(height: 6),
        Text(content),
      ],
    ),
  );


  
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
