import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/chat_screen.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'dart:math';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  // Random user data
  final List<Map<String, String>> _randomUsers = [
    {
      'username': 'John Doe',
      'handle': 'johndoe',
      'profileImage': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'username': 'Sarah Smith',
      'handle': 'sarahsmith',
      'profileImage': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'username': 'Mike Johnson',
      'handle': 'mikej',
      'profileImage': 'https://i.pravatar.cc/150?img=12',
    },
    {
      'username': 'Emily Brown',
      'handle': 'emilybrown',
      'profileImage': 'https://i.pravatar.cc/150?img=9',
    },
    {
      'username': 'David Wilson',
      'handle': 'davidw',
      'profileImage': 'https://i.pravatar.cc/150?img=15',
    },
    {
      'username': 'Lisa Anderson',
      'handle': 'lisaanderson',
      'profileImage': 'https://i.pravatar.cc/150?img=20',
    },
    {
      'username': 'James Taylor',
      'handle': 'jamestaylor',
      'profileImage': 'https://i.pravatar.cc/150?img=13',
    },
    {
      'username': 'Maria Garcia',
      'handle': 'mariagarcia',
      'profileImage': 'https://i.pravatar.cc/150?img=24',
    },
    {
      'username': 'Robert Lee',
      'handle': 'robertlee',
      'profileImage': 'https://i.pravatar.cc/150?img=33',
    },
    {
      'username': 'Jennifer White',
      'handle': 'jenniferwhite',
      'profileImage': 'https://i.pravatar.cc/150?img=47',
    },
    {
      'username': 'Chris Martin',
      'handle': 'chrismartin',
      'profileImage': 'https://i.pravatar.cc/150?img=51',
    },
    {
      'username': 'Amanda Davis',
      'handle': 'amandadavis',
      'profileImage': 'https://i.pravatar.cc/150?img=32',
    },
    {
      'username': 'Kevin Brown',
      'handle': 'kevinbrown',
      'profileImage': 'https://i.pravatar.cc/150?img=58',
    },
    {
      'username': 'Rachel Green',
      'handle': 'rachelgreen',
      'profileImage': 'https://i.pravatar.cc/150?img=45',
    },
    {
      'username': 'Tom Harris',
      'handle': 'tomharris',
      'profileImage': 'https://i.pravatar.cc/150?img=60',
    },
  ];

  final List<String> _sampleMessages = [
    'Hey, how are you?',
    'Did you see the latest update?',
    'Thanks for the help!',
    'Let\'s catch up soon',
    'That\'s awesome!',
    'Check out this link',
    'Working on the project',
    'See you tomorrow',
    'Great idea!',
    'Looking forward to it',
    'Sounds good to me',
    'Will do!',
    'Perfect timing',
    'Just finished the task',
    'Can we talk later?',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getRandomTime() {
    final random = Random();
    final times = ['2m', '5m', '15m', '1h', '2h', '3h', '5h', '1d', '2d', 'Mon', 'Tue'];
    return times[random.nextInt(times.length)];
  }

  Future<void> _loadUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final random = Random();
      List<Map<String, dynamic>> users = [];

      // First, try to load users from Firestore
      if (currentUser != null) {
        try {
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .limit(10)
              .get();

          users = usersSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'username': data['username'] ?? 'User',
              'handle': data['handle'] ?? 'user',
              'profileImage': data['profileImage'] ?? '',
              'lastMessage': _sampleMessages[random.nextInt(_sampleMessages.length)],
              'lastMessageTime': _getRandomTime(),
              'isOnline': random.nextBool(),
            };
          }).toList();
        } catch (e) {
          debugPrint('Firestore error: $e');
        }
      }


      for (var i = 0; i < _randomUsers.length; i++) {
        final randomUser = _randomUsers[i];
        users.add({
          'id': 'random_$i',
          'username': randomUser['username']!,
          'handle': randomUser['handle']!,
          'profileImage': randomUser['profileImage']!,
          'lastMessage': _sampleMessages[random.nextInt(_sampleMessages.length)],
          'lastMessageTime': _getRandomTime(),
          'isOnline': random.nextBool(),
        });
      }

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      
      // Fallback: Show only random users if everything fails
      final random = Random();
      _randomUsers.asMap().entries.map((entry) {
        return {
          'id': 'random_${entry.key}',
          'username': entry.value['username']!,
          'handle': entry.value['handle']!,
          'profileImage': entry.value['profileImage']!,
          'lastMessage': _sampleMessages[random.nextInt(_sampleMessages.length)],
          'lastMessageTime': _getRandomTime(),
          'isOnline': random.nextBool(),
        };
      }).toList();

      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Messages',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined, color: Colors.black),
            onPressed: _showNewMessageDialog,
          ),
        ],
      ),
      drawer: AppDrawer(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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

          // Messages List
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
            const Text(
              'Welcome to your inbox!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black,
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
              child: const Text(
                'Write a message',
                style: TextStyle(
                  color: Colors.white,
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
                    backgroundColor: Colors.grey.shade300,
                    child: user['profileImage'].isEmpty
                        ? Icon(Icons.person, size: 32, color: Colors.grey.shade600)
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
                          border: Border.all(color: Colors.white, width: 2),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black,
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
          followersCount: (user['followers'] ?? 1200) as int,
          followingCount: (user['following'] ?? 300) as int,
          tweetsCount: (user['tweets'] ?? 540) as int,
        ));
  }

  void _showNewMessageDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
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
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterUsers,
                ),
              ),

              // Users List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: user['profileImage'].isNotEmpty
                            ? NetworkImage(user['profileImage'])
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: user['profileImage'].isEmpty
                            ? const Icon(Icons.person)
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
