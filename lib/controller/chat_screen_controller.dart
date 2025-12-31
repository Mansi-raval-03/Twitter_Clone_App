import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/services/notification_service.dart';

class ChatScreenController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final String otherUserId;
  final String otherUserName;
  bool _statusUpdateScheduled = false;

  ChatScreenController({
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  String getChatId() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final ids = [currentUserId, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    final message = messageController.text.trim();
    messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(getChatId())
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'receiverId': otherUserId,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'deliveredAt': null,
            'readAt': null,
          });

      // Update chat metadata
      await FirebaseFirestore.instance.collection('chats').doc(getChatId()).set(
        {
          'participants': [currentUser.uid, otherUserId],
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': currentUser.uid,
          'unreadCounts.$otherUserId': FieldValue.increment(1),
          'unreadCounts.${currentUser.uid}': FieldValue.increment(0),
        },
        SetOptions(merge: true),
      );

      // Send notification to the receiver using NotificationService
      await NotificationService.notifyMessage(
        receiverId: otherUserId,
        messageContent: message,
      );

      scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(getChatId())
          .collection('messages')
          .doc(messageId)
          .delete();

      Get.snackbar(
        'Message deleted',
        'The message has been removed',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
      Get.snackbar(
        'Error',
        'Failed to delete message',
        duration: const Duration(seconds: 2),
      );
    }
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  void scheduleStatusUpdate(QuerySnapshot snap) {
    if (_statusUpdateScheduled) return;
    _statusUpdateScheduled = true;
    Future.microtask(() async {
      try {
        await markDeliveredAndRead(snap);
      } finally {
        _statusUpdateScheduled = false;
      }
    });
  }

  Future<void> markDeliveredAndRead(QuerySnapshot snap) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();
    var hasUpdates = false;

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isIncoming = data['receiverId'] == currentUserId;
      if (!isIncoming) continue;

      final needsDelivered = data['deliveredAt'] == null;
      final needsRead = data['readAt'] == null;

      if (needsDelivered || needsRead) {
        hasUpdates = true;
        final updateData = <String, dynamic>{};
        if (needsDelivered) {
          updateData['deliveredAt'] = FieldValue.serverTimestamp();
        }
        if (needsRead) {
          updateData['readAt'] = FieldValue.serverTimestamp();
          updateData['isRead'] = true;
        }
        batch.update(doc.reference, updateData);
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }

    // Clear unread count for this chat for current user once messages are viewed
    await FirebaseFirestore.instance.collection('chats').doc(getChatId()).set({
      'unreadCounts.$currentUserId': 0,
    }, SetOptions(merge: true));
  }
}
