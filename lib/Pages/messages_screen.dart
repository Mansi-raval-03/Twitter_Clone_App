import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:twitter_clone_app/controller/message_controller.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageController msgcontroller = Get.put(MessageController());
  @override
  Widget build(BuildContext context) {
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
        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Messages',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.email_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => showNewMessageDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: TextField(
              controller: msgcontroller.searchController,
              onChanged: msgcontroller.filterUsers,
              decoration: InputDecoration(
                hintText: 'Search Direct Messages',
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).iconTheme.color,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF2F2F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: msgcontroller.refreshMessages,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: msgcontroller.getConversationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final conversations = snapshot.data ?? [];

                  // Apply search filter if search is active
                  final displayList =
                      msgcontroller.searchController.text.isEmpty
                      ? conversations
                      : conversations.where((user) {
                          final username = user['username']
                              .toString()
                              .toLowerCase();
                          final handle = user['handle']
                              .toString()
                              .toLowerCase();
                          final searchLower = msgcontroller
                              .searchController
                              .text
                              .toLowerCase();
                          return username.contains(searchLower) ||
                              handle.contains(searchLower);
                        }).toList();

                  if (displayList.isEmpty) {
                    return buildEmptyState(context);
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                      indent: 72, // align with avatar edge
                    ),
                    itemBuilder: (context, index) {
                      return buildMessageTile(context, displayList[index]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'messages_fab',
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        onPressed: () => showNewMessageDialog(context),
        child: Icon(
          Icons.email_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to your inbox!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop a line, share posts and more with private conversations between you and others on Twitter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => showNewMessageDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Write a message',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageTile(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // unread count
    final int unreadCount = (user['unreadCount'] ?? 0) is int
        ? (user['unreadCount'] as int)
        : int.tryParse((user['unreadCount'] ?? 0).toString()) ?? 0;
    final bool hasUnread = unreadCount > 0;

    // sender check (keep ONE field in Firestore)
    final String? lastSenderId = user['lastMessageSenderId'];

    final bool showDot =
        hasUnread && lastSenderId != null && lastSenderId != currentUid;

    final avatarProvider =
        user['profileImage'] != null &&
            user['profileImage'].toString().isNotEmpty
        ? resolveImageProvider(user['profileImage'])
        : null;

    return InkWell(
      onTap: () => msgcontroller.navigateToChat(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => msgcontroller.navigateToUserProfile(user['id']),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: avatarProvider,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    child: avatarProvider == null
                        ? Icon(
                            Icons.person,
                            size: 28,
                            color: theme.iconTheme.color,
                          )
                        : null,
                  ),
                  if (user['isOnline'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and time row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['username'] ?? '',
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 15,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user['lastMessageTime'] != null &&
                          user['lastMessageTime'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            user['lastMessageTime'],
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 12,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // handle and message preview
                  Row(
                    children: [
                      Text(
                        '${user['handle'] ?? ''}',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(
                            0.85,
                          ),

                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user['lastMessage'] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(hasUnread ? 1.0 : 0.75),
                            fontSize: 16,

                            fontWeight: hasUnread
                                ? FontWeight.w900
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDot) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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

  // Show New Message Dialog
  void showNewMessageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'New message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).canvasColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: msgcontroller.filterContacts,
                ),
              ),
              // Users List
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    controller: scrollController,
                    itemCount: msgcontroller.filteredContacts.length,
                    itemBuilder: (context, index) {
                      final user = msgcontroller.filteredContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              user['profileImage'] != null &&
                                  user['profileImage'].toString().isNotEmpty
                              ? resolveImageProvider(user['profileImage'])
                              : null,
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          child:
                              (user['profileImage'] == null ||
                                  user['profileImage'].toString().isEmpty)
                              ? Icon(
                                  Icons.person,
                                  color: Theme.of(context).iconTheme.color,
                                )
                              : null,
                        ),
                        title: Text(
                          user['username'],
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('@${user['handle']}'),
                        onTap: () {
                          Navigator.pop(context);
                          msgcontroller.navigateToChat(user);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
