import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class TweetDetailScreen extends StatefulWidget {
  final TweetModel tweet;

  const TweetDetailScreen({super.key, required this.tweet});

  @override
  State<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends State<TweetDetailScreen> {
  late int _likesCount;
  late int _retweetsCount;
  late int _repliesCount;
  bool _isLiked = false;
  bool _isRetweeted = false;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.tweet.likes.length;
    _repliesCount = widget.tweet.comments.length;
    _retweetsCount = 0;
  }

  String _formatDate(DateTime date) {
    return DateFormat('h:mm a · MMM d, y').format(date);
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tweet = widget.tweet;

    return Scaffold(
      appBar: AppBar(title: const Text('Tweet'), elevation: 0.5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Author
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      debugPrint("Opening profile of ${tweet.username}");
                      Get.to(
                        () => UserProfileScreen(
                          userName: tweet.username,
                          userHandle: tweet.handle.replaceAll('@', ''),
                          userBio: '',
                          profileImageUrl: tweet.profileImage,
                          coverImageUrl: '',
                          followersCount: 0,
                          followingCount: 0,
                          tweetsCount: 0,
                        ),
                      );
                    },

                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: tweet.profileImage.isNotEmpty
                          ? NetworkImage(tweet.profileImage)
                          : NetworkImage(
                              'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tweet.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        tweet.handle,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 130),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        isFollowing = !isFollowing;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(isFollowing ? 'Following' : 'Follow'),
                  ),
                ],
              ),
            ),

            /// Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tweet.content,
                style: const TextStyle(fontSize: 20, height: 1.3),
              ),
            ),

            /// Image
            if (tweet.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(tweet.imageUrl),
                ),
              ),

            /// Time
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _formatDate(tweet.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),

            const Divider(),

            /// Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStat(_repliesCount, 'Replies'),
                  const SizedBox(width: 24),
                  _buildStat(_retweetsCount, 'Retweets'),
                  const SizedBox(width: 24),
                  _buildStat(_likesCount, 'Likes'),
                ],
              ),
            ),

            const Divider(),

            /// Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAction(Icons.chat_bubble_outline, _repliesCount, () {}),
                _buildAction(
                  Icons.repeat,
                  _retweetsCount,
                  () {
                    setState(() {
                      _isRetweeted = !_isRetweeted;
                      _retweetsCount += _isRetweeted ? 1 : -1;
                    });
                  },
                  active: _isRetweeted,
                  color: Colors.green,
                ),
                _buildAction(
                  Icons.favorite,
                  _likesCount,
                  () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _likesCount += _isLiked ? 1 : -1;
                    });
                  },
                  active: _isLiked,
                  color: Colors.red,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(int count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatNumber(count),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAction(
    IconData icon,
    int count,
    VoidCallback onTap, {
    bool active = false,
    Color color = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: active ? color : Colors.grey),
          const SizedBox(width: 6),
          Text(
            count > 0 ? _formatNumber(count) : '',
            style: TextStyle(color: active ? color : Colors.grey),
          ),
        ],
      ),
    );
  }
}
