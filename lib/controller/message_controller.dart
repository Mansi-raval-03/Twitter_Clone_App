 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/chat_screen.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';

class MessageController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  
  final RxList<Map<String, dynamic>> allUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allContacts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredContacts = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadAllContacts();
    _listenToConversations();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load users initially
  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        isLoading.value = false;
        return;
      }

      final convSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      List<Map<String, dynamic>> users = [];

      for (final doc in convSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (participants.length != 2) continue;
        
        final otherId = participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        if (otherId.isEmpty) continue;

        try {
          final otherDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .get();
          final otherData = otherDoc.data() ?? {};
          final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
          final unread = (unreadCounts[currentUser.uid] ?? 0) as num;

          users.add({
            'id': otherId,
            'username': otherData['username'] ?? otherData['name'] ?? 'User',
            'handle': otherData['handle'] ??
                (otherData['email'] != null
                    ? otherData['email'].toString().split('@')[0]
                    : 'user'),
            'profileImage': otherData['profileImage'] ?? otherData['photoURL'] ?? '',
            'lastMessage': (data['lastMessage'] ?? '') as String,
            'lastMessageTime': _formatLastMessageTime(
                (data['lastMessageTime'] as Timestamp?)),
            'lastMessageTimestamp': data['lastMessageTime'],
            'isOnline': otherData['isOnline'] ?? false,
            'unreadCount': unread,
          });
        } catch (e) {
          debugPrint('Error loading user $otherId: $e');
        }
      }

      // Sort by lastMessageTimestamp descending (newest first)
      users.sort((a, b) {
        final aTime = a['lastMessageTimestamp'] as Timestamp?;
        final bTime = b['lastMessageTimestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      allUsers.value = users;
      if (searchController.text.isEmpty) {
        filteredUsers.value = users;
      } else {
        filterUsers(searchController.text);
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Real-time stream for conversations
  void _listenToConversations() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .listen((snapshot) async {
      List<Map<String, dynamic>> users = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        // Only show private 1-to-1 conversations
        if (participants.length != 2) continue;
        
        final otherId = participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        if (otherId.isEmpty) continue;

        // fetch other user's profile
        try {
          final otherDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .get();
          final otherData = otherDoc.data() ?? {};
          final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
          final unread = (unreadCounts[currentUser.uid] ?? 0) as num;

          users.add({
            'id': otherId,
            'username': otherData['username'] ?? otherData['name'] ?? 'User',
            'handle': otherData['handle'] ??
                (otherData['email'] != null
                    ? otherData['email'].toString().split('@')[0]
                    : 'user'),
            'profileImage': otherData['profileImage'] ?? otherData['photoURL'] ?? '',
            'lastMessage': (data['lastMessage'] ?? '') as String,
            'lastMessageTime': _formatLastMessageTime(
                (data['lastMessageTime'] as Timestamp?)),
            'lastMessageTimestamp': data['lastMessageTime'],
            'isOnline': otherData['isOnline'] ?? false,
            'unreadCount': unread,
          });
        } catch (e) {
          debugPrint('Error loading user $otherId: $e');
        }
      }

      // Sort by lastMessageTimestamp descending (newest first)
      users.sort((a, b) {
        final aTime = a['lastMessageTimestamp'] as Timestamp?;
        final bTime = b['lastMessageTimestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      allUsers.value = users;
      if (searchController.text.isEmpty) {
        filteredUsers.value = users;
      } else {
        filterUsers(searchController.text);
      }
    });
  }

  // Get real-time conversations stream
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> users = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (participants.length != 2) continue;
        
        final otherId = participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        if (otherId.isEmpty) continue;

        try {
          final otherDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherId)
              .get();
          final otherData = otherDoc.data() ?? {};
          final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
          final unread = (unreadCounts[currentUser.uid] ?? 0) as num;

          users.add({
            'id': otherId,
            'username': otherData['username'] ?? otherData['name'] ?? 'User',
            'handle': otherData['handle'] ??
                (otherData['email'] != null
                    ? otherData['email'].toString().split('@')[0]
                    : 'user'),
            'profileImage': otherData['profileImage'] ?? otherData['photoURL'] ?? '',
            'lastMessage': (data['lastMessage'] ?? '') as String,
            'lastMessageTime': _formatLastMessageTime(
                (data['lastMessageTime'] as Timestamp?)),
            'lastMessageTimestamp': data['lastMessageTime'],
            'isOnline': otherData['isOnline'] ?? false,
            'unreadCount': unread,
          });
        } catch (e) {
          debugPrint('Error loading user $otherId: $e');
        }
      }

      // Sort by lastMessageTimestamp descending (newest first)
      users.sort((a, b) {
        final aTime = a['lastMessageTimestamp'] as Timestamp?;
        final bTime = b['lastMessageTimestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return users;
    });
  }

  String _formatLastMessageTime(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}/${date.year}';
  }

  // Refresh messages - manually reload and stream will continue updating
  Future<void> refreshMessages() async {
    await loadUsers();
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers.value = allUsers;
    } else {
      filteredUsers.value = allUsers.where((user) {
        final username = user['username'].toString().toLowerCase();
        final handle = user['handle'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return username.contains(searchLower) || handle.contains(searchLower);
      }).toList();
    }
  }

  // Load all contacts for starting new conversations (not limited to existing conversations)
  Future<void> loadAllContacts() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(100)
          .get();

      final contacts = usersSnapshot.docs
          .where((d) => d.id != currentUser.uid)
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'username': data['username'] ?? data['name'] ?? 'User',
          'handle': data['handle'] ?? (data['email'] != null ? data['email'].toString().split('@')[0] : 'user'),
          'profileImage': data['profileImage'] ?? data['photoURL'] ?? '',
        };
      }).toList();

      allContacts.value = contacts;
      filteredContacts.value = contacts;
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      allContacts.value = [];
      filteredContacts.value = [];
    }
  }

  void filterContacts(String query) {
    if (query.isEmpty) {
      filteredContacts.value = allContacts;
    } else {
      filteredContacts.value = allContacts.where((user) {
        final username = user['username'].toString().toLowerCase();
        final handle = user['handle'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return username.contains(searchLower) || handle.contains(searchLower);
      }).toList();
    }
  }

  // Navigation methods
  void navigateToChat(Map<String, dynamic> user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final chatId = _chatId(currentUser.uid, user['id']);
      FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'unreadCounts': {currentUser.uid: 0},
      }, SetOptions(merge: true));
    }
    Get.to(() => ChatScreen(
          userId: user['id'],
          userName: user['username'],
          userHandle: user['handle'],
          profileImage: user['profileImage'],
        ));
  }

  String _chatId(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  void navigateToUserProfile(String userId) {
    Get.to(() => UserProfileScreen(viewedUserId: userId));
  }
}
  // UI Methods
  
