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

      // Get current user info
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final username = userData['name'] ?? currentUser.displayName ?? 'User';
      final handle =
          userData['username'] ?? currentUser.email?.split('@')[0] ?? 'user';
      final profileImage =
          userData['profileImage'] ?? currentUser.photoURL ?? '';

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
          'username': username,
          'handle': '@$handle',
          'profileImage': profileImage,
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

      // Get current user info for title and meta
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};
      final username = userData['name'] ?? currentUser.displayName ?? 'User';

      await createNotification(
        toUserId: receiverId,
        type: 'message',
        title: '$username sent you a message',
        body: messageContent,
        meta: {'message': messageContent},
      );
    } catch (e) {
      print('Error notifying message: $e');
    }
  }
}
