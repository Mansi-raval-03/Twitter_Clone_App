import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/Pages/messages_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_detail_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class TweetCardWidget extends StatefulWidget {
  final TweetModel tweet;

  const TweetCardWidget({super.key, required this.tweet});

  @override
  State<TweetCardWidget> createState() => _TweetCardWidgetState();
}

class _TweetCardWidgetState extends State<TweetCardWidget> {
  late bool isLiked;
  late int _likesCount;
  late int _retweetsCount;
  late int _repliesCount;
  late bool _isLiked;
  late bool _isRetweeted;

  @override
  void initState() {
    super.initState();
    isLiked = widget.tweet.isLiked;
    _likesCount = widget.tweet.likes.length;
    _repliesCount = widget.tweet.comments.length;
    _retweetsCount = 0;
    _isLiked = widget.tweet.isLiked;
    _isRetweeted = false;
  }
  
  String _formatNumber(int number) {
    if (number >= 1000 && number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('h:mm a • MMM d').format(widget.tweet.createdAt);

    final words = widget.tweet.content.split(' ');
    final List<InlineSpan> textSpans = words.map((word) {
      final isHashtag = word.startsWith('#');
      final isMention = word.startsWith('@');
      if (isHashtag || isMention) {
        return TextSpan(
          text: '$word ',
          style: TextStyle(
            color: Colors.lightBlueAccent.shade400,
            fontWeight: FontWeight.w600,
          ),
        );
      }
      return TextSpan(text: '$word ');
    }).toList();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TweetDetailScreen(tweet: widget.tweet)),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: widget.tweet.profileImage.isNotEmpty
                  ? NetworkImage(widget.tweet.profileImage)
                  : null,
              radius: 20,
              child: widget.tweet.profileImage.isEmpty
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: widget.tweet.username,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: ' ${widget.tweet.handle}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: ' · $timeString',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade600,),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.35,
                      ),
                      children: textSpans,
                    ),
                  ),
                  if (widget.tweet.imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.network(widget.tweet.imageUrl),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
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