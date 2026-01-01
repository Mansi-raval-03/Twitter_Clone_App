import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Model/notification_Model.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twitter_clone_app/Pages/chat_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/tweet/tweet_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  static const route = '/notification';

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Use Get.find to get the existing controller instance
    // or create one if it doesn't exist (fallback)
    try {
      _controller = Get.find<NotificationController>();
    } catch (e) {
      _controller = Get.put(NotificationController(), permanent: true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _controller.startListener(uid);
      }
    }
  }

  @override
  void dispose() {
    // Don't stop the listener as it's used globally
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // accept both String and Map payloads safely
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is String) {
    } else if (routeArgs is Map) {}

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.person_4_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep,
              color: Theme.of(context).iconTheme.color,
            ),
            tooltip: 'Clear all notifications',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear all notifications?'),
                  content: const Text('This will delete all your notifications.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _controller.deleteAllNotifications();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Mentions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildList(), _buildList(onlyMentions: true)],
      ),
    );
  }

  // list of notifications
  Widget _buildList({bool onlyMentions = false}) {
    return Obx(() {
      final list = onlyMentions
          ? _controller.notifications
                .where((n) => n.type == NotificationType.mention)
                .toList()
          : _controller.notifications;

      if (list.isEmpty) {
        return _emptyState(
          title: onlyMentions ? 'Nothing here yet' : 'No notifications',
          subtitle: onlyMentions
              ? 'Mentions will appear here'
              : 'When someone interacts with you, you’ll see it here.',
        );
      }

      return ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _notificationTile(list[i]),
      );
    });
  }

  // single notification tile
  Widget _notificationTile(AppNotification n) {
    final meta = n.meta;
    final username = meta['username'] ?? 'User';
    final handle = meta['handle'] ?? '';
    final profileImage = meta['profileImage'] ?? '';
    final content = meta['tweetContent'] ?? meta['message'];

    IconData icon;
    Color color;
    String action;

    switch (n.type) {
      case NotificationType.like:
        icon = Icons.favorite;
        color = Colors.red;
        action = 'liked your Tweet';
        break;
      case NotificationType.reply:
        icon = Icons.chat_bubble_outline;
        color = Theme.of(context).colorScheme.primary;
        action = 'replied to your Tweet';
        break;
      case NotificationType.retweet:
        icon = Icons.repeat;
        color = Colors.green;
        action = 'retweeted your Tweet';
        break;
      case NotificationType.follow:
        icon = Icons.person_add;
        color = Theme.of(context).colorScheme.primary;
        action = 'followed you';
        break;
      case NotificationType.message:
        icon = Icons.email_outlined;
        color = Theme.of(context).colorScheme.primary;
        action = 'sent you a message';
        break;
      case NotificationType.mention:
        icon = Icons.alternate_email;
        color = Theme.of(context).colorScheme.primary;
        action = 'mentioned you';
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = Theme.of(context).colorScheme.primary;
        action = 'system notification';
        break;
    }

    return InkWell(
      onTap: () async {
        // Delete notification after tap (mark as read and remove from list)
        await _controller.consumeNotification(n);

        // Navigate based on notification type
        if (n.type == NotificationType.message) {
          final fromId = meta['fromUserId'];
          if (fromId != null) {
            Get.to(
              () => ChatScreen(
                userId: fromId,
                userName: username,
                userHandle: handle,
                profileImage: profileImage,
              ),
            );
            return;
          }
        } else if (n.type == NotificationType.follow) {
          // Navigate to the follower's profile
          final fromId = meta['fromUserId'];
          if (fromId != null) {
            Get.to(() => UserProfileScreen(viewedUserId: fromId));
            return;
          }
        } else if (n.type == NotificationType.like ||
            n.type == NotificationType.retweet ||
            n.type == NotificationType.reply ||
            n.type == NotificationType.mention) {
          // Navigate to the tweet detail page
          final tweetId = meta['tweetId'];
          if (tweetId != null) {
            // Get tweet and navigate to detail screen
            try {
              final tweetDoc = await FirebaseFirestore.instance
                  .collection('tweets')
                  .doc(tweetId)
                  .get();
              if (tweetDoc.exists) {
                final tweet = TweetModel.fromDoc(tweetDoc);
                Get.to(() => TweetDetailScreen(tweet: tweet));
                return;
              }
            } catch (e) {
              Get.snackbar('Error', 'Could not load tweet');
            }
          }
        }

        // Fallback to user profile
        final fromId = meta['fromUserId'];
        if (fromId != null) {
          Get.to(() => UserProfileScreen(viewedUserId: fromId));
        }
      },
      child: Container(
        color: n.read
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).colorScheme.primary.withOpacity(0.08),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: resolveImageProvider(profileImage),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                text: username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ' $action'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 8),
                    Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(n.time, locale: 'en_short'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // empty state widget
  Widget _emptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
