import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotificationType type;
  final bool read;
  final Map<String, dynamic> meta;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.read,
    required this.meta,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    NotificationType type = NotificationType.system;
    final typeString = (data['type'] ?? '').toString().toLowerCase();

    // Map notification type strings to enum
    switch (typeString) {
      case 'like':
        type = NotificationType.like;
        break;
      case 'reply':
        type = NotificationType.reply;
        break;
      case 'retweet':
        type = NotificationType.retweet;
        break;
      case 'follow':
        type = NotificationType.follow;
        break;
      case 'message':
        type = NotificationType.message;
        break;
      case 'mention':
        type = NotificationType.mention;
        break;
      default:
        type = NotificationType.system;
    }

    return AppNotification(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: type,
      read: data['read'] ?? false,
      meta: Map<String, dynamic>.from(data['meta'] ?? {}),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      type: type,
      read: read ?? this.read,
      meta: meta,
    );
  }
}
