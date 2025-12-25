import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';

class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final ids = [currentUserId, widget.userId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_getChatId())
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'receiverId': widget.userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat metadata
      await FirebaseFirestore.instance.collection('chats').doc(_getChatId()).set({
        'participants': [currentUser.uid, widget.userId],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUser.uid,
      }, SetOptions(merge: true));

      // Write a notification document for the receiver so their client
      // (and NotificationController listener) can pick it up.
      try {
        final now = DateTime.now();
        await FirebaseFirestore.instance.collection('notifications').add({
          'to': widget.userId,
          'from': currentUser.uid,
          'title': 'New message',
          'body': message,
          'time': FieldValue.serverTimestamp(),
          'type': 'message',
          'read': false,
          'meta': {
            'username': currentUser.displayName ?? '',
            'handle': currentUser.email != null ? currentUser.email!.split('@')[0] : '',
            'profileImage': currentUser.photoURL ?? '',
            'message': message,
            'timeAgo': DateFormat('h:mm a').format(now),
          },
        });
      } catch (e) {
        debugPrint('Failed to write notification: $e');
      }

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  void _openProfile() {
    Get.to(() => UserProfileScreen(
      viewedUserId: widget.userId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0.4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () =>  Get.back(),
        ),
        title: InkWell(
          onTap: _openProfile,
          child: Row(
            children: [
              CircleAvatar(
                    radius: 16,
                    backgroundImage: resolveImageProvider(widget.profileImage),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: widget.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: TextStyle(
                        color: Theme.of(context).appBarTheme.foregroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@${widget.userHandle}',
                      style: TextStyle(
                        color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId())
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: resolveImageProvider(widget.profileImage),
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          child: widget.profileImage.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${widget.userHandle}',
                          style: TextStyle(
                            color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  try {
                    _scrollToBottom();
                  } catch (_) {}
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final time = timestamp != null
                        ? _formatTime(timestamp.toDate())
                        : '';

                    return _buildMessageBubble(
                      message['message'],
                      isMe,
                      time,
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Start a new message',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade100,
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
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Colors.lightBlueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: resolveImageProvider(widget.profileImage),
              backgroundColor: Colors.grey.shade300,
              child: widget.profileImage.isEmpty
                  ? const Icon(Icons.person, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.lightBlueAccent : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}