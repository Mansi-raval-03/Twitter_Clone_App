import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';

enum NotificationType {
  like,
  comment,
  retweet,
  follow,
  mention,
}

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

  final List<NotificationItem> _notifications = [
    NotificationItem(
      type: NotificationType.like,
      username: 'John Doe',
      handle: '@johndoe',
      profileImage: '',
      tweetContent: 'Just deployed my new Flutter app! #Flutter #Mobile',
      timeAgo: '2m',
    ),
    NotificationItem(
      type: NotificationType.follow,
      username: 'Sarah Smith',
      handle: '@sarahsmith',
      profileImage: '',
      timeAgo: '15m',
    ),
    NotificationItem(
      type: NotificationType.retweet,
      username: 'Mike Johnson',
      handle: '@mikej',
      profileImage: '',
      tweetContent: 'Learning Dart is easier than I thought!',
      timeAgo: '1h',
    ),
    NotificationItem(
      type: NotificationType.comment,
      username: 'Emily Brown',
      handle: '@emilybrown',
      profileImage: '',
      tweetContent: 'What a beautiful day for coding',
      timeAgo: '3h',
    ),
    NotificationItem(
      type: NotificationType.mention,
      username: 'David Wilson',
      handle: '@davidw',
      profileImage: '',
      tweetContent: 'Hey @mansi, check out this awesome tutorial!',
      timeAgo: '5h',
    ),
    NotificationItem(
      type: NotificationType.like,
      username: 'Lisa Anderson',
      handle: '@lisaanderson',
      profileImage: '',
      tweetContent: 'Firebase is amazing for real-time apps',
      timeAgo: '1d',
    ),
    NotificationItem(
      type: NotificationType.mention,
      username: 'M Wilson',
      handle: '@davidw',
      profileImage: '',
      tweetContent: 'Hey @mansi, check out this awesome tutorial!',
      timeAgo: '7h',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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
            icon: const Icon(Icons.person_4_outlined, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
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
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        return _buildNotificationTile(_notifications[index]);
      },
    );
  }

  Widget _buildMentionsNotifications() {
    final mentions = _notifications.where((n) => n.type == NotificationType.mention).toList();
    
    if (mentions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Nothing to see here — yet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When someone mentions you, youll find it here.',
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
      case NotificationType.comment:
        iconData = Icons.chat_bubble_outline;
        iconColor = Colors.lightBlueAccent;
        actionText = 'replied to your Tweet';
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
    }

    return InkWell(
      onTap: () {
        Get.to(UserProfileScreen(
          userName: notification.username,
          userHandle: notification.handle,
          userBio: 'User bio',
          profileImageUrl: notification.profileImage,
          coverImageUrl: '',
          followersCount: 0,
          followingCount: 0,
          tweetsCount: 0,
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
                        backgroundImage: notification.profileImage.isNotEmpty
                            ? NetworkImage(notification.profileImage)
                            : null,
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