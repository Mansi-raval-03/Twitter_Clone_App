import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/chat_screen.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
// Real data only: remove local mock/random user data

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  // Contacts used for composing a new message (search across all users)
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];

  // Load users from Firestore; no local mock users or sample messages

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadAllContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      List<Map<String, dynamic>> users = [];

      if (currentUser != null) {
        try {
          // Load only conversations that include the current user.
          final convSnapshot = await FirebaseFirestore.instance
              .collection('conversations')
              .where('participants', arrayContains: currentUser.uid)
              .get();

          for (final doc in convSnapshot.docs) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            // Only show private 1-to-1 conversations
            if (participants.length != 2) continue;
            final otherId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
            if (otherId.isEmpty) continue;

            // fetch other user's profile
            final otherDoc = await FirebaseFirestore.instance.collection('users').doc(otherId).get();
            final otherData = otherDoc.data() ?? {};

            users.add({
              'id': otherId,
              'username': otherData['username'] ?? otherData['name'] ?? 'User',
              'handle': otherData['handle'] ?? (otherData['email'] != null ? otherData['email'].toString().split('@')[0] : 'user'),
              'profileImage': otherData['profileImage'] ?? otherData['photoURL'] ?? '',
              'lastMessage': (data['lastMessage'] ?? '') as String,
              'lastMessageTime': _formatLastMessageTime((data['lastMessageTimestamp'] as Timestamp?)),
              'isOnline': otherData['isOnline'] ?? false,
            });
          }
        } catch (e) {
          debugPrint('Firestore error: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _allUsers = [];
        _filteredUsers = [];
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final username = user['username'].toString().toLowerCase();
          final handle = user['handle'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return username.contains(searchLower) || handle.contains(searchLower);
        }).toList();
      }
    });
  }

  // Load all contacts for starting new conversations (not limited to existing conversations)
  Future<void> _loadAllContacts() async {
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

      if (!mounted) return;
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (!mounted) return;
      setState(() {
        _allContacts = [];
        _filteredContacts = [];
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((user) {
          final username = user['username'].toString().toLowerCase();
          final handle = user['handle'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return username.contains(searchLower) || handle.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.person_4_outlined, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
       
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Messages',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
                ),
            ),
        ),
        actions: [
          
          IconButton(
            icon: Icon(Icons.email_outlined, color: Theme.of(context).iconTheme.color),
            onPressed: _showNewMessageDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search Direct Messages',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
              
                ),
              ),
                ),
              ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                      indent: 88,
                    ),
                    itemBuilder: (context, index) {
                      return _buildMessageTile(_filteredUsers[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'messages_fab',
        backgroundColor: Colors.lightBlueAccent,
        shape: const CircleBorder(),
        onPressed: _showNewMessageDialog,
        child: const Icon(Icons.email_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.email_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Welcome to your inbox!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop a line, share posts and more with private conversations between you and others on Twitter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showNewMessageDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Write a message',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> user) {
    return InkWell(
      onTap: () {
        Get.to(() => ChatScreen(
              userId: user['id'],
              userName: user['username'],
              userHandle: user['handle'],
              profileImage: user['profileImage'],
            ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _openProfile(user),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: user['profileImage'].isNotEmpty
                        ? NetworkImage(user['profileImage'])
                        : null,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: user['profileImage'].isEmpty
                        ? Icon(Icons.person, size: 32, color: Theme.of(context).iconTheme.color)
                        : null,
                  ),
                  if (user['isOnline'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user['lastMessageTime'].isNotEmpty)
                        Text(
                          user['lastMessageTime'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '@${user['handle']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '·',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user['lastMessage'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic> user) {
    Get.to(() => UserProfileScreen(
          userName: user['username'],
          userHandle: user['handle'],
          userBio: 'Bio unavailable',
          profileImageUrl: user['profileImage'],
          coverImageUrl: '',
          followersCount: (() {
            final v = user['followers'];
            if (v is int) return v;
            if (v is num) return v.toInt();
            return int.tryParse(v?.toString() ?? '') ?? 1200;
          })(),
          followingCount: (() {
            final v = user['following'];
            if (v is int) return v;
            if (v is num) return v.toInt();
            return int.tryParse(v?.toString() ?? '') ?? 300;
          })(),
          tweetsCount: (() {
            final v = user['tweets'];
            if (v is int) return v;
            if (v is num) return v.toInt();
            return int.tryParse(v?.toString() ?? '') ?? 540;
          })(),
        ));
  }

  void _showNewMessageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).iconTheme.color ?? Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'New message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                    filled: true,
                    fillColor: Theme.of(context).canvasColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterContacts,
                ),
              ),

              // Users List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final user = _filteredContacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: user['profileImage'].isNotEmpty
                            ? NetworkImage(user['profileImage'])
                            : null,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        child: user['profileImage'].isEmpty
                            ? Icon(Icons.person, color: Theme.of(context).iconTheme.color)
                            : null,
                      ),
                      title: Text(
                        user['username'],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('@${user['handle']}'),
                      onTap: () {
                        Navigator.pop(context);
                        Get.to(() => ChatScreen(
                              userId: user['id'],
                              userName: user['username'],
                              userHandle: user['handle'],
                              profileImage: user['profileImage'],
                            ));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
