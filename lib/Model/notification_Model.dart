// ---------------- MODEL ----------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    NotificationType type = NotificationType.system;
    try {
      type = NotificationType.values.firstWhere(
        (e) => describeEnum(e) == data['type'],
      );
    } catch (_) {}

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
