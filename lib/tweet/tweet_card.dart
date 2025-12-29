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
import 'package:cloud_firestore/cloud_firestore.dart';

class TweetCardWidget extends StatefulWidget {
  final TweetModel tweet;

  const TweetCardWidget({super.key, required this.tweet});

  @override
  State<TweetCardWidget> createState() => _TweetCardWidgetState();
}

class _TweetCardWidgetState extends State<TweetCardWidget> {
  // Local state for optimistic updates
  late int _localLikesCount;
  late int _localRetweetsCount;
  late bool _localIsLiked;
  late bool _localIsRetweeted;
  bool _isProcessingLike = false;
  bool _isProcessingRetweet = false;

  @override
  void initState() {
    super.initState();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    _localLikesCount = widget.tweet.likes.length;
    _localRetweetsCount = widget.tweet.retweets.length;
    _localIsLiked = widget.tweet.likes.contains(currentUid);
    _localIsRetweeted = widget.tweet.retweets.contains(currentUid);
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

  // Helper function to safely convert Firebase data to List<String>
  List<String> _safeListConversion(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) return [];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder to listen to real-time updates from Firebase
    return StreamBuilder<DocumentSnapshot>(
      stream: TweetService.getTweetStream(widget.tweet.id),
      builder: (context, snapshot) {
        // While loading, show the widget with initial data
        if (!snapshot.hasData) {
          return _buildTweetCard(context, widget.tweet);
        }

        // If tweet is deleted, show nothing
        if (!snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        // Get updated data from Firebase
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return _buildTweetCard(context, widget.tweet);
        }

        // Update local state from Firebase if not processing an action
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final firebaseLikes = _safeListConversion(data['likes']);
        final firebaseRetweets = _safeListConversion(data['retweets']);
        
        if (!_isProcessingLike) {
          _localLikesCount = firebaseLikes.length;
          _localIsLiked = firebaseLikes.contains(currentUid);
        }
        if (!_isProcessingRetweet) {
          _localRetweetsCount = firebaseRetweets.length;
          _localIsRetweeted = firebaseRetweets.contains(currentUid);
        }

        // Create updated tweet model with real-time data
        final updatedTweet = TweetModel(
          id: widget.tweet.id,
          uid: widget.tweet.uid,
          username: widget.tweet.username,
          handle: widget.tweet.handle,
          profileImage: widget.tweet.profileImage,
          content: widget.tweet.content,
          imageUrl: widget.tweet.imageUrl,
          likes: firebaseLikes,
          retweets: firebaseRetweets,
          comments: _safeListConversion(data['comments']),
          createdAt: widget.tweet.createdAt,
          isLiked: _localIsLiked,
          retweetedBy: widget.tweet.retweetedBy,
          isRetweet: widget.tweet.isRetweet,
          originalTweetId: widget.tweet.originalTweetId,
          originalUsername: widget.tweet.originalUsername,
          originalHandle: widget.tweet.originalHandle,
          originalProfileImage: widget.tweet.originalProfileImage,
          originalContent: widget.tweet.originalContent,
          originalImageUrl: widget.tweet.originalImageUrl,
          originalCreatedAt: widget.tweet.originalCreatedAt,
        );

        return _buildTweetCard(context, updatedTweet);
      },
    );
  }

  Widget _buildTweetCard(BuildContext context, TweetModel tweet) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    // Use local state for instant UI updates
    final likesCount = _localLikesCount;
    final retweetsCount = _localRetweetsCount;
    final repliesCount = tweet.comments.length;
    final isLiked = _localIsLiked;
    final isRetweeted = _localIsRetweeted;

    // If this doc is a retweet, display the original tweet's author/content
    final isRetweet = tweet.isRetweet;
    final headerRetweeter = isRetweet ? tweet.username : '';
    final displayUsername = isRetweet
        ? tweet.originalUsername
        : tweet.username;
    final displayHandle = isRetweet
        ? tweet.originalHandle
        : tweet.handle;
    // Show the retweeter's avatar in the card header. The original author's
    // details (username/handle/content) are shown in the body when `isRetweet`.
    final displayProfileImage = tweet.profileImage;
    final displayContent = isRetweet
        ? tweet.originalContent
        : tweet.content;
    final displayImage = isRetweet
        ? tweet.originalImageUrl
        : tweet.imageUrl;
    final displayCreatedAt = isRetweet
        ? (tweet.originalCreatedAt ?? tweet.createdAt)
        : tweet.createdAt;
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
            builder: (_) => TweetDetailScreen(tweet: tweet),
          ),
        );
      },
      child: Container(
        width: double.infinity,
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
                mainAxisSize: MainAxisSize.min,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                            builder: (_) => Options(tweet: tweet),
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
                        child: Image.network(
                          displayImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                        _buildAction(
                        Icons.chat_bubble_outline,
                        repliesCount,
                        () {
                         Get.to(() => TweetDetailScreen(tweet: tweet));
                        },
                        ),
                      _buildAction(
                        Icons.repeat,
                        retweetsCount,
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
                          
                          // Optimistic update - update UI immediately
                          setState(() {
                            _isProcessingRetweet = true;
                            _localIsRetweeted = !_localIsRetweeted;
                            _localRetweetsCount += _localIsRetweeted ? 1 : -1;
                          });

                          try {
                            final targetId = tweet.isRetweet
                                ? tweet.originalTweetId
                                : tweet.id;
                            
                            // Firebase update happens in background
                            await TweetService.toggleRetweet(
                              targetId,
                              currentUid,
                            );
                            
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _localIsRetweeted
                                      ? 'Retweeted'
                                      : 'Retweet removed',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } catch (e) {
                            // Revert optimistic update on error
                            if (mounted) {
                              setState(() {
                                _localIsRetweeted = !_localIsRetweeted;
                                _localRetweetsCount += _localIsRetweeted ? 1 : -1;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isProcessingRetweet = false;
                              });
                            }
                          }
                        },
                        active: isRetweeted,
                        color: Colors.green,
                      ),
                      _buildAction(
                        Icons.favorite,
                        likesCount,
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
                          
                          // Optimistic update - update UI immediately
                          setState(() {
                            _isProcessingLike = true;
                            _localIsLiked = !_localIsLiked;
                            _localLikesCount += _localIsLiked ? 1 : -1;
                          });

                          try {
                            // Firebase update happens in background
                            await TweetService.toggleLike(
                              tweet.id,
                              tweet.likes,
                            );
                          } catch (e) {
                            // Revert optimistic update on error
                            if (mounted) {
                              setState(() {
                                _localIsLiked = !_localIsLiked;
                                _localLikesCount += _localIsLiked ? 1 : -1;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isProcessingLike = false;
                              });
                            }
                          }
                        },
                        active: isLiked,
                        color: Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () async {
                          try {
                            final text =
                                '${tweet.username} ${tweet.handle}: ${tweet.content}';
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
          // Share and Bookmark options available for all tweets
          _optionTile(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () async {
              Navigator.pop(context);
              try {
                final text =
                    '${tweet.username} ${tweet.handle}: ${tweet.content}';
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tweet copied to clipboard'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share failed: $e')),
                );
              }
            },
          ),

          _optionTile(
            icon: Icons.bookmark_border,
            label: 'Bookmark',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bookmarked'),
                ),
              );
            },
          ),

          // Delete option only for the tweet author
          if (isMyTweet) ...[
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
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : Theme.of(context).iconTheme.color),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        onTap: onTap,
      ),
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
