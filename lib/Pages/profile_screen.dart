import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
import 'package:twitter_clone_app/Pages/edit_profile.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

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

  // Add local editable fields (shown on screen)
  late String _name;
  late String _username;
  late String _bio;
  late String _location;
  String _website = '';
  late String _profileImageUrl;

  late List<TweetModel> _tweets;
  late List<TweetModel> _replies;
  late List<TweetModel> _media;
  late List<TweetModel> _likes;

  final _random = Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize from widget.user
    _name = widget.user.name;
    _username = widget.user.username;
    _bio = widget.user.bio;
    _location = widget.user.location;
    _profileImageUrl = widget.user.profileImage;

    _tweets = _buildRandomTweets(count: 10, includeImages: true);
    _replies = _buildRandomTweets(count: 6, asReply: true);
    _media = _tweets.where((t) => t.imageUrl.isNotEmpty).toList();
    _likes = _buildRandomTweets(count: 8, includeImages: true);
  }

  List<TweetModel> _buildRandomTweets({
    int count = 8,
    bool includeImages = false,
    bool asReply = false,
  }) {
    final contents = [
      "Small steps, big results.",
      "Stay focused, stay humble.",
      "Building amazing things with Flutter.",
      "Coffee first, code later ☕",
      "Growth doesn’t always look like progress.",
    ];

    final images = [
      "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
      "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
    ];

    return List.generate(count, (i) {
      final hasImage = includeImages && _random.nextBool();
      return TweetModel(
        id: 'id_$i',
        uid: 'uid_$i',
        username: widget.user.name,
        handle: '@${widget.user.username}',
        profileImage: widget.user.profileImage,
        content: asReply
            ? "Reply: ${contents[_random.nextInt(contents.length)]}"
            : contents[_random.nextInt(contents.length)],
        imageUrl: hasImage ? images[_random.nextInt(images.length)] : '',
        likes: [],
        comments: [],
        createdAt: DateTime.now(),
        isLiked: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.user.followers > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          /// COVER IMAGE
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
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
                Image.network(
                  widget.user.coverImage,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.35),
                      ],
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

          /// PROFILE HEADER
          SliverToBoxAdapter(
            child: Padding(
               
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProfileHeader(isVerified)),
                  _buildEditProfileButton(), // this will now await and update state
                ],
              ),
            ),
          ),

          /// META + STATS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildUserMeta(),
                  const SizedBox(height: 8),
                  _buildUserStats(),
                ],
              ),
            ),
          ),

          /// TABS
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Tweets'),
                  Tab(text: 'Replies'),
                  Tab(text: 'Media'),
                  Tab(text: 'Likes'),
                ],
              ),
            ),
          ),
        ],

        /// TAB CONTENT
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTweetList(_tweets),
            _buildTweetList(_replies),
            _buildMediaGrid(_media),
            _buildTweetList(_likes),
          ],
        ),
      ),
    );
  }


  Widget _buildProfilePicture() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 48,
        backgroundImage: NetworkImage(_profileImageUrl), // use local state
      ),
    );
  }

  /// HEADER
  Widget _buildProfileHeader(bool isVerified) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _name, // from state
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 20, color: Color(0xFF1D9BF0)),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text('@$_username', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 10),
        Text(_bio, style: const TextStyle(fontSize: 15, height: 1.4)),
      ],
    );
  }

  /// META
  Widget _buildUserMeta() {
    return Row(
      children: [
        if (_location.isNotEmpty) ...[
          const Icon(Icons.location_on, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(_location),
          const SizedBox(width: 16),
        ],
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        const Text('Joined March 2020'),
        if (_website.isNotEmpty) ...[
          const SizedBox(width: 16),
          const Icon(Icons.link, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(_website),
        ],
      ],
    );
  }

  /// STATS
  Widget _buildUserStats() {
    return Row(
      children: [
        _stat('2500000', 'Followers'),
        const SizedBox(width: 30),
        _stat('500', 'Following'),
      ],
    );
  }

  Widget _stat(String count, String label) {
    return Row(
      children: [
        Text(count,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return OutlinedButton(
      onPressed: () async {
        final result = await Get.to(() => EditProfilePage(
              username: _username,
              bio: _bio,
              profileImageUrl: _profileImageUrl,
              name: _name,
              location: _location,
              website: _website,
            ));

        if (result is Map) {
          setState(() {
            // Only overwrite when provided
            _username = (result['username'] as String?)?.trim().isNotEmpty == true
                ? result['username']
                : _username;
            _bio = (result['bio'] as String?)?.trim().isNotEmpty == true
                ? result['bio']
                : _bio;
            _name = (result['name'] as String?)?.trim().isNotEmpty == true
                ? result['name']
                : _name;
            _location = (result['location'] as String?)?.trim().isNotEmpty == true
                ? result['location']
                : _location;
            _website = (result['website'] as String?)?.trim() ?? _website;

            // If later you add image picking and return 'profileImageUrl', handle it here:
            if ((result['profileImageUrl'] as String?)?.isNotEmpty == true) {
              _profileImageUrl = result['profileImageUrl'];
            }
          });
        }
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildTweetList(List<TweetModel> list) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade300),
      itemBuilder: (_, i) => TweetCardWidget(tweet: list[i]),
    );
  }

  Widget _buildMediaGrid(List<TweetModel> media) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: media.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          media[i].imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// STICKY TAB BAR
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_) => false;
}
