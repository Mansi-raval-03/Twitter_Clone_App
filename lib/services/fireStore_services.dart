import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification Services
  Future<void> createNotification({
    required String recipientId,
    required String senderId,
    required String type, // 'like', 'comment', 'follow', 'retweet'
    required String message,
    required String tweetId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'senderId': senderId,
        'type': type,
        'message': message,
        'tweetId': tweetId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Chat Message Services
  Future<void> sendMessage({
    required String receiverId,
    required String messageText,
  }) async {
    try {
      final senderId = _auth.currentUser!.uid;
      final chatRoomId = getChatRoomId(senderId, receiverId);

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await _firestore.collection('chatRooms').doc(chatRoomId).set(
        {
          'lastMessage': messageText,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'participants': [senderId, receiverId],
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessages(String receiverId) {
    final userId = _auth.currentUser!.uid;
    final chatRoomId = getChatRoomId(userId, receiverId);

    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatRooms() {
    final userId = _auth.currentUser!.uid;
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

  Future<void> markMessageAsRead(
      String receiverId, String messageId) async {
    final userId = _auth.currentUser!.uid;
    final chatRoomId = getChatRoomId(userId, receiverId);

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }
}
