import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized notification creation service
class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Create a notification in Firestore
  /// This will trigger the NotificationController listener to show it in-app
  static Future<void> createNotification({
    required String toUserId,
    required String
    type, // 'like', 'retweet', 'reply', 'follow', 'message', etc.
    required String title,
    required String body,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't send notification to yourself
      if (currentUser.uid == toUserId) return;

      // Get SENDER's user info (the person who triggered the notification, NOT the receiver)
      final senderDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final senderData = senderDoc.data() ?? {};
      
      // Get sender's display name from 'name' field in Firestore
      final senderName = senderData['name'] ?? senderData['username'] ?? currentUser.displayName ?? 'User';
      
      // Get sender's handle from 'handle' field, removing '@' if present
      final senderHandle = (senderData['handle'] ?? '').toString().replaceFirst('@', '');
      final fallbackHandle = senderData['email']?.split('@')[0] ?? currentUser.email?.split('@')[0] ?? 'user';
      final finalHandle = senderHandle.isNotEmpty ? senderHandle : fallbackHandle;
      
      final senderProfileImage = senderData['profileImage'] ?? senderData['profilePicture'] ?? currentUser.photoURL ?? '';

      print('📤 Creating notification: type=$type, from=${currentUser.uid}, to=$toUserId, senderName=$senderName');

      await _firestore.collection('notifications').add({
        'to': toUserId,
        'from': currentUser.uid,
        'type': type,
        'title': title,
        'body': body,
        'time': FieldValue.serverTimestamp(),
        'read': false,
        'sendPush':
            true, // Flag to trigger push notification via Cloud Function
        'meta': {
          'username': senderName,
          'handle': '@$finalHandle',
          'profileImage': senderProfileImage,
          'fromUserId': currentUser.uid,
          ...?meta,
        },
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Create notification for a tweet like
  static Future<void> notifyLike({
    required String tweetOwnerId,
    required String tweetId,
    String? tweetContent,
  }) async {
    await createNotification(
      toUserId: tweetOwnerId,
      type: 'like',
      title: 'New like',
      body: 'liked your tweet',
      meta: {'tweetId': tweetId, 'tweetContent': tweetContent ?? ''},
    );
  }

  /// Create notification for a retweet
  static Future<void> notifyRetweet({
    required String tweetOwnerId,
    required String tweetId,
    String? tweetContent,
  }) async {
    await createNotification(
      toUserId: tweetOwnerId,
      type: 'retweet',
      title: 'New retweet',
      body: 'retweeted your tweet',
      meta: {'tweetId': tweetId, 'tweetContent': tweetContent ?? ''},
    );
  }

  /// Create notification for a reply
  static Future<void> notifyReply({
    required String tweetOwnerId,
    required String tweetId,
    required String replyContent,
  }) async {
    await createNotification(
      toUserId: tweetOwnerId,
      type: 'reply',
      title: 'New reply',
      body: 'replied to your tweet',
      meta: {'tweetId': tweetId, 'replyContent': replyContent},
    );
  }

  /// Create notification for a follow
  static Future<void> notifyFollow({required String followedUserId}) async {
    await createNotification(
      toUserId: followedUserId,
      type: 'follow',
      title: 'New follower',
      body: 'started following you',
      meta: {},
    );
  }

  /// Create notification for a mention
  static Future<void> notifyMention({
    required String mentionedUserId,
    required String tweetId,
    String? tweetContent,
  }) async {
    await createNotification(
      toUserId: mentionedUserId,
      type: 'mention',
      title: 'New mention',
      body: 'mentioned you in a tweet',
      meta: {'tweetId': tweetId, 'tweetContent': tweetContent ?? ''},
    );
  }

  /// Create notification for a message
  static Future<void> notifyMessage({
    required String receiverId,
    required String messageContent,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't send notification to yourself
      if (currentUser.uid == receiverId) return;

      // Get SENDER's (current user) info - NOT the receiver's
      final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final senderData = senderDoc.data() ?? {};
      final senderUsername = senderData['name'] ?? currentUser.displayName ?? 'User';

      await createNotification(
        toUserId: receiverId,
        type: 'message',
        title: '$senderUsername sent you a message',
        body: messageContent,
        meta: {'message': messageContent},
      );
    } catch (e) {
      print('Error notifying message: $e');
    }
  }
}
