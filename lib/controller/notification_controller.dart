import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { reply, mention, retweet, like, follow, message, system }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotificationType type;
  final bool read;
  final Map<String, dynamic>? meta;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.read = false,
    this.meta,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? time,
    NotificationType? type,
    bool? read,
    Map<String, dynamic>? meta,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      type: type ?? this.type,
      read: read ?? this.read,
      meta: meta ?? this.meta,
    );
  }
}

class NotificationController extends GetxController {
  // Reactive list used by UI (Obx)
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  final RxSet<NotificationType> _activeFilters = <NotificationType>{}.obs;
  final RxBool _onlyUnread = false.obs;

  // Filters and unread toggle applied
  List<AppNotification> get filteredNotifications {
    final list = notifications.where((n) {
      if (_onlyUnread.value && n.read) return false;
      if (_activeFilters.isNotEmpty && !_activeFilters.contains(n.type)) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  bool get onlyUnread => _onlyUnread.value;
  Set<NotificationType> get activeFilters => Set.unmodifiable(_activeFilters);
  int get unreadCount => notifications.where((n) => !n.read).length;

  // Basic CRUD
  void addNotification(AppNotification notification) {
    notifications.add(notification);
    update();
  }

  void addNotifications(List<AppNotification> notificationsList) {
    notifications.addAll(notificationsList);
    update();
  }

  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    update();
  }

  void clearAll() {
    notifications.clear();
    update();
  }

  // Read/unread management
  void markAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !notifications[idx].read) {
      notifications[idx] = notifications[idx].copyWith(read: true);
      notifications.refresh();
      update();
    }
  }

  void markAsUnread(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && notifications[idx].read) {
      notifications[idx] = notifications[idx].copyWith(read: false);
      notifications.refresh();
      update();
    }
  }

  void markAllAsRead() {
    var changed = false;
    for (var i = 0; i < notifications.length; i++) {
      if (!notifications[i].read) {
        notifications[i] = notifications[i].copyWith(read: true);
        changed = true;
      }
    }
    if (changed) {
      notifications.refresh();
      update();
    }
  }

  // Filtering
  void toggleFilter(NotificationType type) {
    if (_activeFilters.contains(type)) {
      _activeFilters.remove(type);
    } else {
      _activeFilters.add(type);
    }
    update();
  }

  void setFilters(Set<NotificationType> types) {
    _activeFilters
      ..clear()
      ..addAll(types);
    update();
  }

  void clearFilters() {
    if (_activeFilters.isNotEmpty) {
      _activeFilters.clear();
      update();
    }
  }

  void setOnlyUnread(bool value) {
    if (_onlyUnread.value != value) {
      _onlyUnread.value = value;
      update();
    }
  }

  // Utilities
  int countByType(NotificationType type) =>
      notifications.where((n) => n.type == type).length;

  // Example loader (can be replaced by real API call)
  Future<void> loadMockNotifications({int count = 8, Duration delay = const Duration(milliseconds: 300)}) async {
    await Future.delayed(delay);
    final now = DateTime.now();
    final sample = List.generate(count, (i) {
      final types = NotificationType.values;
      final type = types[i % types.length];
      return AppNotification(
        id: 'notif_${now.millisecondsSinceEpoch}_$i',
        title: _titleForType(type),
        body: 'Sample ${describeEnum(type)} notification #$i',
        time: now.subtract(Duration(minutes: i * 5)),
        type: type,
        read: i % 3 == 0,
        meta: {'sampleIndex': i},
      );
    });
    addNotifications(sample);
  }

  static String _titleForType(NotificationType type) {
    switch (type) {
      case NotificationType.reply:
        return 'New reply';
      case NotificationType.mention:
        return 'You were mentioned';
      case NotificationType.retweet:
        return 'Retweeted';
      case NotificationType.like:
        return 'Someone liked your tweet';
      case NotificationType.message:
        return 'New message';
      case NotificationType.follow:
        return 'New follower';
      case NotificationType.system:
      return 'Notice';
    }
  }

  // Firestore listener subscription stored on the controller instance
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
}

// Extend controller to listen to Firestore notifications for current user
extension NotificationControllerFirestore on NotificationController {

  void startFirestoreListener(String userId) {
    this._firestoreSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: userId)
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        final typeStr = (data['type'] ?? '').toString();
        NotificationType type = NotificationType.system;
        try {
          type = NotificationType.values.firstWhere((v) => describeEnum(v) == typeStr);
        } catch (_) {}

        return AppNotification(
          id: d.id,
          title: data['title']?.toString() ?? NotificationController._titleForType(type),
          body: data['body']?.toString() ?? '',
          time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
          type: type,
          read: data['read'] == true,
          meta: (data['meta'] as Map<String, dynamic>?) ?? {},
        );
      }).toList();

      // Update local list
      notifications
        ..clear()
        ..addAll(list);
      update();
    }, onError: (e) {
      debugPrint('Notification listener error: $e');
    });
  }

  void stopFirestoreListener() {
    this._firestoreSub?.cancel();
    this._firestoreSub = null;
  }
}


