import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/controller/home_conteoller.dart';
import 'package:twitter_clone_app/tweet/tweet_detail_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';
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

    _isLiked = widget.tweet.likes.contains(
      FirebaseAuth.instance.currentUser?.uid,
    );
    _isRetweeted = widget.tweet.retweets.contains(
      FirebaseAuth.instance.currentUser?.uid,
    );
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

    // If this doc is a retweet, display the original tweet's author/content
    final isRetweet = widget.tweet.isRetweet;
    final headerRetweeter = isRetweet ? widget.tweet.username : '';
    final displayUsername = isRetweet
        ? widget.tweet.originalUsername
        : widget.tweet.username;
    final displayHandle = isRetweet
        ? widget.tweet.originalHandle
        : widget.tweet.handle;
    // Show the retweeter's avatar in the card header. The original author's
    // details (username/handle/content) are shown in the body when `isRetweet`.
    final displayProfileImage = widget.tweet.profileImage;
    final displayContent = isRetweet
        ? widget.tweet.originalContent
        : widget.tweet.content;
    final displayImage = isRetweet
        ? widget.tweet.originalImageUrl
        : widget.tweet.imageUrl;
    final displayCreatedAt = isRetweet
        ? (widget.tweet.originalCreatedAt ?? widget.tweet.createdAt)
        : widget.tweet.createdAt;
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
          MaterialPageRoute(
            builder: (_) => TweetDetailScreen(tweet: widget.tweet),
          ),
        );
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: resolveImageProvider(displayProfileImage),
              radius: 20,
              child: displayProfileImage.isEmpty
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Retweet header: shown above the author row for clarity
                  if (isRetweet)
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0, bottom: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: headerRetweeter,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(text: ' '),
                                TextSpan(
                                  text: 'retweeted',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: displayUsername,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: ' $displayHandle',
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
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => Options(tweet: widget.tweet),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
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
                        _buildAction(
                        Icons.chat_bubble_outline,
                        _repliesCount,
                        () {
                         Get.to(() => TweetDetailScreen(tweet: widget.tweet));
                        },
                        ),
                      _buildAction(
                        Icons.repeat,
                        _retweetsCount,
                        () async {
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUid == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please sign in to retweet'),
                              ),
                            );
                            return;
                          }
                          try {
                            final targetId = widget.tweet.isRetweet
                                ? widget.tweet.originalTweetId
                                : widget.tweet.id;
                            await TweetService.toggleRetweet(
                              targetId,
                              currentUid,
                            );
                            if (!mounted) return;
                            setState(() {
                              _isRetweeted = !_isRetweeted;
                              _retweetsCount += _isRetweeted ? 1 : -1;
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isRetweeted
                                      ? 'Retweeted'
                                      : 'Retweet removed',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        active: _isRetweeted,
                        color: Colors.green,
                      ),
                      _buildAction(
                        Icons.favorite,
                        _likesCount,
                        () async {
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUid == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please sign in to like'),
                              ),
                            );
                            return;
                          }
                          try {
                            await TweetService.toggleLike(
                              widget.tweet.id,
                              widget.tweet.likes,
                            );
                            if (!mounted) return;
                            setState(() {
                              _isLiked = !_isLiked;
                              _likesCount += _isLiked ? 1 : -1;
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        active: _isLiked,
                        color: Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () async {
                          try {
                            final text =
                                '${widget.tweet.username} ${widget.tweet.handle}: ${widget.tweet.content}';
                            await Clipboard.setData(ClipboardData(text: text));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tweet copied to clipboard'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Share failed: $e')),
                            );
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
          // Only show action options for tweets that belong to the current user.
          if (!isMyTweet)
            // For other users' tweets, don't show like/share/bookmark/report.
            // Provide a simple cancel entry so the sheet can be closed gracefully.
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),

          if (isMyTweet) ...[
            _optionTile(
              icon: tweet.isLiked ? Icons.favorite : Icons.favorite_border,
              label: tweet.isLiked ? 'Unlike' : 'Like',
              onTap: () {
                Navigator.pop(context);
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

            const Divider(),

            _optionTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                // Keep bottom sheet mounted; confirmation dialog will close
                // itself and then deletion will occur while the sheet context
                // remains valid.
                _confirmDelete(context);
              },
            ),
          ],
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
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tweet?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the confirmation dialog first
              Navigator.pop(dialogContext);

              try {
                // Perform deletion while the bottom sheet (and its context)
                // is still mounted so we can reliably show a SnackBar.
                await TweetService.deleteTweet(tweet.id);

                // Update local HomeController cache so UI updates immediately
                try {
                  final homeController = Get.find<HomeController>();
                  homeController.tweets.removeWhere((t) => t.id == tweet.id);
                } catch (_) {}

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tweet deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                // Now close the bottom sheet
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting tweet: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
          
  }
}
