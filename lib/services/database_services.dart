import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/services/notification_service.dart';

class DatabaseServices {
  static Future<int> followersnum(String userId) async {
    if (userId.toString().trim().isEmpty) return 0;
    QuerySnapshot followersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userFollowers')
        .get();
    return followersSnapshot.docs.length;
  }

  /// Follow a user: add entries to both users' subcollections and update counts
  static Future<void> followUser(
    String currentUid,
    Map<String, dynamic> currentUserData,
    String targetUid,
    Map<String, dynamic> targetUserData,
  ) async {
    if (currentUid.trim().isEmpty || targetUid.trim().isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();

    final targetFollowersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('userFollowers')
        .doc(currentUid);
    batch.set(targetFollowersRef, {
      'uid': currentUid,
      'username': currentUserData['username'] ?? '',
      'name': currentUserData['name'] ?? '',
      'profileImage': currentUserData['profileImage'] ?? '',
      'followedAt': FieldValue.serverTimestamp(),
    });

    final currentFollowingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('userFollowing')
        .doc(targetUid);
    batch.set(currentFollowingRef, {
      'uid': targetUid,
      'username': targetUserData['username'] ?? '',
      'name': targetUserData['name'] ?? '',
      'profileImage': targetUserData['profileImage'] ?? '',
      'followedAt': FieldValue.serverTimestamp(),
    });

    // increment counts on both user docs
    final targetUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid);
    final currentUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid);
    batch.update(targetUserDoc, {'followers': FieldValue.increment(1)});
    batch.update(currentUserDoc, {'following': FieldValue.increment(1)});

    await batch.commit();

    // Send follow notification to the target user
    await NotificationService.notifyFollow(followedUserId: targetUid);
  }

  static Future<void> unfollowUser(String currentUid, String targetUid) async {
    if (currentUid.trim().isEmpty || targetUid.trim().isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final targetFollowersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('userFollowers')
        .doc(currentUid);
    batch.delete(targetFollowersRef);

    final currentFollowingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('userFollowing')
        .doc(targetUid);
    batch.delete(currentFollowingRef);

    final targetUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid);
    final currentUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid);
    batch.update(targetUserDoc, {'followers': FieldValue.increment(-1)});
    batch.update(currentUserDoc, {'following': FieldValue.increment(-1)});

    await batch.commit();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> followersStream(
    String userId,
  ) {
    if (userId.trim().isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userFollowers')
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> followingStream(
    String userId,
  ) {
    if (userId.trim().isEmpty) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userFollowing')
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  static Future<bool> isFollowing(String currentUid, String targetUid) async {
    if (currentUid.trim().isEmpty || targetUid.trim().isEmpty) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('userFollowing')
        .doc(targetUid)
        .get();
    return doc.exists;
  }
}
