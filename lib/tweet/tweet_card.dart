import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/tweet/tweet_detail_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/services/tweet_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

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
    _retweetsCount = widget.tweet.retweets.length;
    
    _isLiked = widget.tweet.likes.contains(FirebaseAuth.instance.currentUser?.uid);
    _isRetweeted = widget.tweet.retweets.contains(FirebaseAuth.instance.currentUser?.uid);
  }

  @override
  void didUpdateWidget(covariant TweetCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    // update local counters if parent provided new tweet data
    if (mounted) {
      setState(() {
        _likesCount = widget.tweet.likes.length;
        _repliesCount = widget.tweet.comments.length;
        _retweetsCount = widget.tweet.retweets.length;
        _isLiked = widget.tweet.likes.contains(currentUid);
        _isRetweeted = widget.tweet.retweets.contains(currentUid);
      });
    }
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // If this doc is a retweet, display the original tweet's author/content
    final isRetweet = widget.tweet.isRetweet;
    final headerRetweeter = isRetweet ? widget.tweet.username : '';
    final displayUsername = isRetweet ? widget.tweet.originalUsername : widget.tweet.username;
    final displayHandle = isRetweet ? widget.tweet.originalHandle : widget.tweet.handle;
    final displayProfileImage = isRetweet ? widget.tweet.originalProfileImage : widget.tweet.profileImage;
    final displayContent = isRetweet ? widget.tweet.originalContent : widget.tweet.content;
    final displayImage = isRetweet ? widget.tweet.originalImageUrl : widget.tweet.imageUrl;
    final displayCreatedAt = isRetweet ? (widget.tweet.originalCreatedAt ?? widget.tweet.createdAt) : widget.tweet.createdAt;
    final timeString = DateFormat('h:mm a • MMM d').format(displayCreatedAt);

    final words = displayContent.split(' ');
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
              backgroundImage: displayProfileImage.isNotEmpty ? NetworkImage(displayProfileImage) : null,
              radius: 20,
              child: displayProfileImage.isEmpty ? const Icon(Icons.person_outline) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Show retweet header when this doc represents a retweet
                      if (isRetweet)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.repeat, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                '$headerRetweeter retweeted',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: displayUsername, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
                              TextSpan(text: ' $displayHandle', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              TextSpan(text: ' · $timeString', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                     IconButton(
  icon: Icon(
    Icons.more_horiz,
    size: 18,
    color: Colors.grey.shade600,
  ),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Options(
        tweet: widget.tweet,
      ),
    );
  },
),


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
                  if (displayImage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.network(displayImage),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                 Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAction(Icons.chat_bubble_outline, _repliesCount, () {
                  // Open detail screen to reply
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TweetDetailScreen(tweet: widget.tweet)),
                  );
                }),
                _buildAction(
                  Icons.repeat,
                  _retweetsCount,
                  () async {
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to retweet')));
                      return;
                    }
                      try {
                      final targetId = widget.tweet.isRetweet ? widget.tweet.originalTweetId : widget.tweet.id;
                      await TweetService.toggleRetweet(targetId, currentUid);
                      setState(() {
                        _isRetweeted = !_isRetweeted;
                        _retweetsCount += _isRetweeted ? 1 : -1;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isRetweeted ? 'Retweeted' : 'Retweet removed')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  active: _isRetweeted,
                  color: Colors.green,
                ),
                _buildAction(
                  Icons.favorite,
                  _likesCount,
                  () async {
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to like')));
                      return;
                    }
                    try {
                      await TweetService.toggleLike(widget.tweet.id, widget.tweet.likes);
                      setState(() {
                        _isLiked = !_isLiked;
                        _likesCount += _isLiked ? 1 : -1;
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  active: _isLiked,
                  color: Colors.red,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () async {
                    try {
                      final text = '${widget.tweet.username} ${widget.tweet.handle}: ${widget.tweet.content}';
                      await Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tweet copied to clipboard')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
                    }
                  },
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

class Options extends StatelessWidget {
  final TweetModel tweet;

  const Options({super.key, required this.tweet});

  bool get isMyTweet {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;
    return tweet.uid == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _optionTile(
            icon: tweet.isLiked ? Icons.favorite : Icons.favorite_border,
            label: tweet.isLiked ? 'Unlike' : 'Like',
            onTap: () {
              Navigator.pop(context);
              // TODO: toggle like
            },
          ),

          _optionTile(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          _optionTile(
            icon: Icons.bookmark_border,
            label: 'Bookmark',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          if (isMyTweet) const Divider(),

          if (isMyTweet)
            _optionTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),

          if (!isMyTweet)
            _optionTile(
              icon: Icons.report_outlined,
              label: 'Report',
              isDestructive: false,
              onTap: () {
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tweet?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TweetService.deleteTweet(tweet.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tweet deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting tweet: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
