import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/settings_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/services/database_services.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  
  late TextEditingController _searchController;
  late TabController _tabController;
  bool isSearching = false;
  bool isLoading = false;
  String searchQuery = '';
  List<Map<String, dynamic>> userResults = [];
  List<TweetModel> tweetResults = [];
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        isSearching = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      searchQuery = '';
      userResults.clear();
      tweetResults.clear();
    });
  }

  Future<void> _performSearch(String query) async {
    searchQuery = query;
    setState(() {
      isLoading = true;
      isSearching = true;
    });

    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      userResults = usersSnap.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();

      final tweetsSnap = await FirebaseFirestore.instance
          .collection('tweets')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      tweetResults = tweetsSnap.docs
          .map((d) => TweetModel.fromDoc(d.data() as DocumentSnapshot))
          .toList();
    } catch (_) {
      // ignore errors for now
    } finally {
      setState(() {
        isLoading = false;
      });
    }

    if (query.isNotEmpty && !recentSearches.contains(query)) {
      recentSearches.insert(0, query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.person_4_outlined, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Explore',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  if (isSearching) 
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _clearSearch();
                      },
                    ),
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _performSearch(value);
                          } else {
                            _clearSearch();
                          }
                        },
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search Twitter',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  if (!isSearching) const SizedBox(width: 8),
                  if (!isSearching)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen()
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Tabs (when searching)
            if (isSearching) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.lightBlueAccent,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Users'),
                    Tab(text: 'Tweets'),
                  ],
                ),
              ),
            ],

            // Content
            Expanded(
              child: isSearching
                  ? (isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildUserResults(),
                              _buildTweetResults(),
                            ],
                          ))
                  : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      recentSearches.clear();
                    });
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
          ...recentSearches.map(
            (search) => ListTile(
              leading: Icon(Icons.search, color: Colors.grey.shade600),
              title: Text(search),
              trailing: IconButton(
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                onPressed: () {
                  setState(() {
                    recentSearches.remove(search);
                  });
                },
              ),
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Search for people and tweets',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserResults() {
    if (userResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No users found for "$searchQuery"',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: userResults.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final user = userResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage:
                user['profileImage'] != null && user['profileImage'].isNotEmpty
                ? NetworkImage(user['profileImage'])
                : null,
            child: user['profileImage'] == null || user['profileImage'].isEmpty
                ? const Icon(Icons.person_outline)
                : null,
          ),
          title: Text(
            user['username'] ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '@${user['handle'] ?? 'user'}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Builder(builder: (context) {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null || user['id'] == currentUser.uid) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<bool>(
              future: DatabaseServices.isFollowing(currentUser.uid, user['id']),
              builder: (context, snap) {
                final isFollowing = snap.data ?? false;
                return OutlinedButton(
                  onPressed: () async {
                    if (isFollowing) {
                      await DatabaseServices.unfollowUser(currentUser.uid, user['id']);
                    } else {
                      final currentUserData = {
                        'username': currentUser.displayName ?? '',
                        'name': currentUser.displayName ?? '',
                        'profileImage': currentUser.photoURL ?? '',
                      };
                      final targetUserData = {
                        'username': user['username'] ?? '',
                        'name': user['name'] ?? user['username'] ?? '',
                        'profileImage': user['profileImage'] ?? '',
                      };
                      await DatabaseServices.followUser(currentUser.uid, currentUserData, user['id'], targetUserData);
                    }
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: isFollowing ? Colors.blue : null,
                    foregroundColor: isFollowing ? Colors.white : null,
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                );
              },
            );
          }),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(viewedUserId: user['id'])),
            );
          },
        );
      },
    );
  }

  Widget _buildTweetResults() {
    if (tweetResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No tweets found for "$searchQuery"',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: tweetResults.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        return TweetCardWidget(tweet: tweetResults[index]);
      },
    );
  }
}
