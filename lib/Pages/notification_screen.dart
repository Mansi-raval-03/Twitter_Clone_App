import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';

class NotificationItem {
  final NotificationType type;
  final String username;
  final String handle;
  final String profileImage;
  final String? tweetContent;
  final String timeAgo;
  final bool isRead;

  NotificationItem({
    required this.type,
    required this.username,
    required this.handle,
    required this.profileImage,
    this.tweetContent,
    required this.timeAgo,
    this.isRead = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Ensure controller is registered with Get for access by GetBuilder

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final controller = Get.put(NotificationController());
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) controller.startFirestoreListener(uid);
  }

  @override
  void dispose() {
    // stop listening when screen disposed
    try {
      final c = Get.isRegistered<NotificationController>() ? Get.find<NotificationController>() : null;
      c?.stopFirestoreListener();
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.person_4_outlined, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Notifications',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).textTheme.titleLarge?.color,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.lightBlueAccent,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Mentions'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllNotifications(),
                  _buildMentionsNotifications(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotifications() {
    // Use Obx to react to changes in the controller's notification list in real-time.
    return GetBuilder<NotificationController>(builder: (c) {
      final rx = c.notifications;
      if (rx.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone interacts with you, you’ll see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

        final list = rx
          .map((n) => NotificationItem(
            type: n.type,
            username: n.meta?['username']?.toString() ?? '',
            handle: n.meta?['handle']?.toString() ?? '',
            profileImage: n.meta?['profileImage']?.toString() ?? '',
            tweetContent: n.meta?['tweetContent']?.toString() ?? n.meta?['message']?.toString(),
            timeAgo: n.meta?['timeAgo']?.toString() ?? '',
            isRead: n.read,
            ))
          .toList();

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final n = list[index];
          return _buildNotificationTile(n);
        },
      );
    });
  }

  Widget _buildMentionsNotifications() {
    // Filter mentions reactively
    return GetBuilder<NotificationController>(builder: (c) {
      final rx = c.notifications;
      final rawMentions = rx.where((n) => n.type == NotificationType.mention).toList();

      if (rawMentions.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Nothing to see here — yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When someone mentions you, you’ll find it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

        final mentions = rawMentions
          .map((n) => NotificationItem(
            type: n.type,
            username: n.meta?['username']?.toString() ?? '',
            handle: n.meta?['handle']?.toString() ?? '',
            profileImage: n.meta?['profileImage']?.toString() ?? '',
            tweetContent: n.meta?['tweetContent']?.toString(),
            timeAgo: n.meta?['timeAgo']?.toString() ?? '',
            isRead: n.read,
            ))
          .toList();

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: mentions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          return _buildNotificationTile(mentions[index]);
        },
      );
    });
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    IconData iconData;
    Color iconColor;
    String actionText;

    switch (notification.type) {
      case NotificationType.like:
        iconData = Icons.favorite;
        iconColor = Colors.red;
        actionText = 'liked your Tweet';
        break;
      case NotificationType.reply:
        iconData = Icons.chat_bubble_outline;
        iconColor = Colors.lightBlueAccent;
        actionText = 'replied to your Tweet';
        break;
      case NotificationType.message:
        iconData = Icons.email_outlined;
        iconColor = Colors.lightBlueAccent;
        actionText = 'sent you a message';
        break;
      case NotificationType.retweet:
        iconData = Icons.repeat;
        iconColor = Colors.green;
        actionText = 'retweeted your Tweet';
        break;
      case NotificationType.follow:
        iconData = Icons.person_add;
        iconColor = Colors.lightBlueAccent;
        actionText = 'followed you';
        break;
      case NotificationType.mention:
        iconData = Icons.alternate_email;
        iconColor = Colors.lightBlueAccent;
        actionText = 'mentioned you';
        break;
      case NotificationType.system:
        throw UnimplementedError();
    }

    return InkWell(
      onTap: () {
        Get.to(UserProfileScreen(
          viewedUserId: notification.handle,
        ));
      },
      child: Container(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(iconData, color: iconColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: resolveImageProvider(notification.profileImage),
                        child: notification.profileImage.isEmpty
                            ? const Icon(Icons.person_outline, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: notification.username,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: ' $actionText',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (notification.tweetContent != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notification.tweetContent!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}