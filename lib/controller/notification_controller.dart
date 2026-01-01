import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/Model/notification_Model.dart';

///  ENUM
enum NotificationType { reply, mention, retweet, like, follow, message, system }

///  CONTROLLER
class NotificationController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reactive State
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxSet<NotificationType> activeFilters = <NotificationType>{}.obs;
  final RxBool onlyUnread = false.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  ///  DERIVED DATA
  List<AppNotification> get filteredNotifications {
    final list = notifications.where((n) {
      if (onlyUnread.value && n.read) return false;
      if (activeFilters.isNotEmpty && !activeFilters.contains(n.type))
        return false;
      return true;
    }).toList();

    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  int get unreadCount => notifications.where((n) => !n.read).length;

  int countByType(NotificationType type) =>
      notifications.where((n) => n.type == type).length;

  ///  FIRESTORE LISTENER
  void startListener(String userId) {
    _subscription?.cancel();

    debugPrint(' Starting notification listener for user: $userId');

    _subscription = _db
        .collection('notifications')
        .where('to', isEqualTo: userId)
        .orderBy('time', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              debugPrint(
                ' Received ${snapshot.docChanges.length} notification changes',
              );

              for (final change in snapshot.docChanges) {
                final doc = change.doc;
                final Map<String, dynamic> data = (doc.data() ?? {});
                final notif = AppNotification.fromFirestore(doc.id, data);

                debugPrint(
                  ' Processing notification: ${change.type.name} - ${notif.title} - ${notif.type}',
                );

                switch (change.type) {
                  case DocumentChangeType.added:
                    // Remove any duplicate and insert newest at top
                    notifications.removeWhere((n) => n.id == notif.id);
                    notifications.insert(0, notif);
                    debugPrint(
                      ' Added notification. Total count: ${notifications.length}',
                    );

                    // show an in-app notification for new unread items
                    if (notif.read == false) {
                      // For messages, show sender's username as title
                      String displayTitle = notif.title;
                      if (notif.type == NotificationType.message) {
                        // Use sender's username from meta (the person who sent the message)
                        displayTitle = notif.meta['username'] ?? 'Someone';
                        debugPrint('📩 Message notification: from="${notif.meta['username']}" fromUserId="${notif.meta['fromUserId']}"');
                      }
                      
                      Get.snackbar(
                        displayTitle,
                        notif.body,
                        snackPosition: SnackPosition.TOP,
                        duration: const Duration(seconds: 3),
                      );
                    }
                    break;
                  case DocumentChangeType.modified:
                    final idx = notifications.indexWhere(
                      (n) => n.id == notif.id,
                    );
                    if (idx != -1) {
                      notifications[idx] = notif;
                      debugPrint(' Modified notification at index $idx');
                    } else {
                      notifications.insert(0, notif);
                      debugPrint(
                        ' Added modified notification (not found in list)',
                      );
                    }
                    break;
                  case DocumentChangeType.removed:
                    notifications.removeWhere((n) => n.id == notif.id);
                    debugPrint(
                      ' Removed notification. Total count: ${notifications.length}',
                    );
                    break;
                }
              }

              // keep list consistent and sorted by time (newest first)
              notifications.sort((a, b) => b.time.compareTo(a.time));
              notifications.refresh();
              debugPrint(
                ' Final notification count: ${notifications.length}',
              );
            } catch (e) {
              debugPrint(' Notification listener processing error: $e');
            }
          },
          onError: (e) {
            debugPrint(' Notification listener error: $e');
          },
        );
  }

  void stopListener() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void onClose() {
    stopListener();
    super.onClose();
  }

  ///  READ / DELETE NOTIFICATIONS
  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].read) return;

    notifications[index] = notifications[index].copyWith(read: true);
    notifications.refresh();

    await _db.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> markAllAsRead() async {
    final batch = _db.batch();

    for (final n in notifications.where((n) => !n.read)) {
      batch.update(_db.collection('notifications').doc(n.id), {'read': true});
    }

    await batch.commit();

    notifications.assignAll(
      notifications.map((n) => n.copyWith(read: true)).toList(),
    );
  }

  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
    notifications.removeWhere((n) => n.id == id);
  }

  Future<void> deleteAllNotifications() async {
    final batch = _db.batch();

    for (final n in notifications) {
      batch.delete(_db.collection('notifications').doc(n.id));
    }

    await batch.commit();
    notifications.clear();
    debugPrint('🗑️ All notifications deleted');
  }

  Future<void> consumeNotification(AppNotification n) async {
    // mark read locally, then remove from backend so it disappears after tap
    await markAsRead(n.id);
    await deleteNotification(n.id);
  }

  ///  FILTERS
  void toggleFilter(NotificationType type) {
    activeFilters.contains(type)
        ? activeFilters.remove(type)
        : activeFilters.add(type);
  }

  void clearFilters() => activeFilters.clear();

  void setOnlyUnread(bool value) => onlyUnread.value = value;
}
