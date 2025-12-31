const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to send push notifications when a new notification is created
 * Triggers on new documents in the 'notifications' collection
 */
exports.sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // Check if push notification should be sent
    if (!notification.sendPush) {
      console.log('Push notification disabled for this notification');
      return null;
    }

    const toUserId = notification.to;
    const title = notification.title || 'New Notification';
    const body = notification.body || '';
    const type = notification.type || 'system';
    const meta = notification.meta || {};

    try {
      // Get the recipient's FCM token from their user document
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(toUserId)
        .get();

      if (!userDoc.exists) {
        console.log(`User ${toUserId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token found for user ${toUserId}`);
        return null;
      }

      // Check if user has push notifications enabled
      const pushEnabled = userData.pushNotifications !== false; // Default to true
      if (!pushEnabled) {
        console.log(`Push notifications disabled for user ${toUserId}`);
        return null;
      }

      // For message notifications, use username as title instead of "username sent you a message"
      let notificationTitle = title;
      if (type === 'message' && meta.username) {
        notificationTitle = meta.username;
      }

      // Create the notification payload
      const message = {
        token: fcmToken,
        notification: {
          title: notificationTitle,
          body: body,
        },
        data: {
          notificationId: context.params.notificationId,
          type: type,
          fromUserId: meta.fromUserId || '',
          username: meta.username || '',
          handle: meta.handle || '',
          tweetId: meta.tweetId || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            icon: 'ic_launcher',
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notificationTitle,
                body: body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent push notification:', response);

      // Update the notification document to mark push as sent
      await snap.ref.update({
        pushSent: true,
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return response;
    } catch (error) {
      console.error('Error sending push notification:', error);
      
      // Mark the notification as failed
      await snap.ref.update({
        pushSent: false,
        pushError: error.message,
        pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

/**
 * Optional: Clean up old FCM tokens when they become invalid
 */
exports.cleanupInvalidTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    console.log('Cleaning up invalid FCM tokens...');
    // You can implement token validation logic here if needed
    return null;
  });
