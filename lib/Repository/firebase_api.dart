import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/main.dart';

/// Background handler must be a top-level function
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM][background] title: ${message.notification?.title ?? message.data['title']}');
  print('[FCM][background] body: ${message.notification?.body ?? message.data['body']}');
  print('[FCM][background] data: ${message.data}');
}

class FirebaseApi {
  factory FirebaseApi() => _instance;
  FirebaseApi._internal();
  static final FirebaseApi _instance = FirebaseApi._internal();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initNotifications() async {
    await _fm.requestPermission(alert: true, badge: true, sound: true);
    final token = await _fm.getToken();
    print('Firebase Messaging Token: $token');

    await _initLocalNotifications();
    await _initPushNotifications();
  }

  Future<void> _initPushNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
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
    final android = AndroidInitializationSettings('@mipmap/ic_launcher'); // <-- use mipmap
    final settings = InitializationSettings(android: android, iOS: ios);

    await localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload == null) return;
        try {
          final Map<String, dynamic> map = jsonDecode(payload) as Map<String, dynamic>;
          _navigateToNotificationScreen(map);
        } catch (e) {
          print('Failed to parse notification payload: $e');
        }
      },
    );

    final platform = localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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
