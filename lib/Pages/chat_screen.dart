import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';
import 'package:twitter_clone_app/controller/chat_screen_controller.dart';
import 'package:twitter_clone_app/Model/chat_Model.dart';

class ChatScreen extends StatelessWidget {
  // User details for the chat
  final String userId;
  final String userName;
  final String userHandle;
  final String profileImage;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userHandle,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(
      ChatScreenController(otherUserId: userId, otherUserName: userName),
      tag: userId,
    );

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onSurface = colors.onSurface;
    final surface = colors.surface;
    final surfaceVariant = colors.surfaceContainerHighest;
    final primary = colors.primary;
    final onPrimary = colors.onPrimary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surface,
        elevation: theme.appBarTheme.elevation ?? 0.4,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: InkWell(
          onTap: () => _openProfile(userId),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: resolveImageProvider(profileImage),
                backgroundColor: surfaceVariant,
                child: profileImage.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 18,
                        color: onSurface.withOpacity(0.7),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@$userHandle',
                      style: TextStyle(
                        color: onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: controller.getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(
                    theme,
                    surfaceVariant,
                    profileImage,
                    userName,
                    userHandle,
                  );
                }

                final messages = snapshot.data!.docs;
                controller.scheduleStatusUpdate(snapshot.data!);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    controller.scrollToBottom();
                  } catch (_) {}
                });

                return ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final message = ChatMessage.fromFirestore(
                      messages[index].id,
                      messageData,
                    );
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    final isMe = message.senderId == currentUserId;
                    final time = message.timestamp != null
                        ? controller.formatTime(message.timestamp!)
                        : '';
                    final status = message.getStatus(currentUserId);
                    final isNewMessage = !isMe && !message.isRead;

                    return _buildMessageBubble(
                      context,
                      controller,
                      message,
                      isMe,
                      time,
                      status,
                      profileImage,
                      isNewMessage,
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(
            context,
            controller,
            theme,
            surface,
            surfaceVariant,
            primary,
            onPrimary,
          ),
        ],
      ),
    );
  }

  void _openProfile(String userId) {
    Get.to(() => UserProfileScreen(viewedUserId: userId));
  }

  Widget _buildEmptyState(
    ThemeData theme,
    Color surfaceVariant,
    String profileImage,
    String userName,
    String userHandle,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: resolveImageProvider(profileImage),
            backgroundColor: surfaceVariant,
            child: profileImage.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '@$userHandle',
            style: TextStyle(
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: TextStyle(
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatScreenController controller,
    ChatMessage message,
    bool isMe,
    String time,
    MessageStatus status,
    String profileImage,
    bool isNewMessage,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Highlight new messages with a more vibrant color
    final bubbleColor = isMe
        ? (theme.brightness == Brightness.light
              ? colors.primaryContainer
              : colors.primary.withOpacity(0.15))
        : isNewMessage
        ? (theme.brightness == Brightness.light
              ? colors.secondaryContainer
              : colors.secondary.withOpacity(0.2))
        : colors.surfaceContainerHighest;

    final textColor = isMe
        ? (theme.brightness == Brightness.light
              ? colors.onPrimaryContainer
              : colors.onSurface)
        : theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: resolveImageProvider(profileImage),
              backgroundColor: theme.dividerColor,
              child: profileImage.isEmpty
                  ? const Icon(Icons.person, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isMe
                  ? () => _showDeleteMessageDialog(
                      context,
                      controller,
                      message.id,
                    )
                  : null,
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 6),
                            bottomRight: Radius.circular(isMe ? 6 : 18),
                          ),
                          // Add subtle border for new messages
                          border: isNewMessage
                              ? Border.all(
                                  color: colors.secondary.withOpacity(0.5),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: isNewMessage
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // New message indicator dot
                      if (isNewMessage)
                        Positioned(
                          top: 0,
                          right: isMe ? null : 0,
                          left: isMe ? 0 : null,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (time.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 6,
                        left: 12,
                        right: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            _messageStatusIcon(context, status),
                          ],
                          if (isNewMessage && !isMe) ...[
                            const SizedBox(width: 6),
                            Text(
                              'NEW',
                              style: TextStyle(
                                color: colors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageStatusIcon(BuildContext context, MessageStatus status) {
    IconData icon;
    Color? color;
    final theme = Theme.of(context);

    switch (status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = theme.iconTheme.color?.withOpacity(0.6);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = theme.iconTheme.color?.withOpacity(0.6);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = theme.colorScheme.primary;
        break;
    }
    return Icon(icon, size: 16, color: color);
  }

  void _showDeleteMessageDialog(
    BuildContext context,
    ChatScreenController controller,
    String messageId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteMessage(messageId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ChatScreenController controller,
    ThemeData theme,
    Color surface,
    Color surfaceVariant,
    Color primary,
    Color onPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.messageController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Start a new message',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
                filled: true,
                fillColor:
                    theme.inputDecorationTheme.fillColor ?? surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => controller.sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: primary,
            child: IconButton(
              icon: Icon(Icons.send, color: onPrimary, size: 20),
              onPressed: () => controller.sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
