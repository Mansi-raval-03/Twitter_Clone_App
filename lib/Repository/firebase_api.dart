import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background handler must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
    '[FCM][background] title: ${message.notification?.title ?? message.data['title']}',
  );
  print(
    '[FCM][background] body: ${message.notification?.body ?? message.data['body']}',
  );
  print('[FCM][background] data: ${message.data}');
}

class FirebaseApi {
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();
  static final FirebaseApi _instance = FirebaseApi._internal();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel androidChannel =
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

  Future<void> initNotifications() async {
    await _fm.requestPermission(alert: true, badge: true, sound: true);
    final token = await _fm.getToken();
    print('Firebase Messaging Token: $token');

    // Save FCM token to Firestore for current user
    if (token != null) {
      await _saveFcmToken(token);
    }

    // Listen for token refresh
    _fm.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveFcmToken(newToken);
    });

    await _initLocalNotifications();
    await _initPushNotifications();
  }

  /// Save FCM token to user's Firestore document
  Future<void> _saveFcmToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM token saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> _initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];

      if (title == null && body == null && message.data.isEmpty) return;

      localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // <-- use mipmap
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode({
          'title': title,
          'body': body,
          'data': message.data,
        }),
      );
    });
  }

  Future<void> _initLocalNotifications() async {
    final ios = DarwinInitializationSettings();
    final android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    ); // <-- use mipmap
    final settings = InitializationSettings(android: android, iOS: ios);

    await localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == null) return;
        try {
          final Map<String, dynamic> map =
              jsonDecode(payload) as Map<String, dynamic>;
          _navigateToNotificationScreen(map);
        } catch (e) {
          print('Failed to parse notification payload: $e');
        }
      },
    );

    final platform = localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(androidChannel);
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    final Map<String, dynamic> args = {
      'title': message.notification?.title ?? message.data['title'],
      'body': message.notification?.body ?? message.data['body'],
      'data': message.data,
    };

    // navigate to notifications screen when triggered by tap or initial message
    navigatoreKey.currentState?.pushNamed(
      NotificationScreen.route,
      arguments: args,
    );
  }

  void _navigateToNotificationScreen(Map<String, dynamic> payload) {
    navigatoreKey.currentState?.pushNamed(
      NotificationScreen.route,
      arguments: payload,
    );
  }
}
