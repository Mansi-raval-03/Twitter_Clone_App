import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class SearchController extends GetxController implements TickerProvider {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final List<Ticker> _tickers = [];
  List<String> recentSearches = [];
  bool isSearching = false;
  String searchQuery = '';

  List<Map<String, dynamic>> userResults = [];
  List<TweetModel> tweetResults = [];
  bool isLoading = false;

  @override
  void onInit() {
    super.onInit();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick, debugLabel: 'created by SearchController');
    _tickers.add(ticker);
    return ticker;
  }

  @override
  void dispose() {
    for (final t in _tickers) {
      t.dispose();
    }
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      isSearching = false;
      searchQuery = '';
      userResults = [];
      tweetResults = [];
      update();
      return;
    }

    isSearching = true;
    searchQuery = query;
    isLoading = true;
    update();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final queryLower = query.toLowerCase();

      // Search all tweets from home timeline
      final tweetsSnapshot = await FirebaseFirestore.instance
          .collection('tweets')
          .orderBy('createdAt', descending: true)
          .get();

      final tweets = tweetsSnapshot.docs
          .map((doc) => TweetModel.fromDoc(doc))
          .where(
            (tweet) =>
                tweet.content.toLowerCase().contains(queryLower) ||
                tweet.username.toLowerCase().contains(queryLower) ||
                tweet.handle.toLowerCase().contains(queryLower),
          )
          .toList();

      // Search users - prioritize current user
      List<Map<String, dynamic>> users = [];

      // First, add current user if matches
      if (currentUser != null) {
        final currentUsername = currentUser.displayName ?? '';
        final currentHandle = currentUser.email?.split('@')[0] ?? '';

        if (currentUsername.toLowerCase().contains(queryLower) ||
            currentHandle.toLowerCase().contains(queryLower) ||
            'mansi'.toLowerCase().contains(queryLower)) {
          users.add({
            'id': currentUser.uid,
            'username': currentUsername.isNotEmpty ? currentUsername : 'Mansi',
            'handle': currentHandle.isNotEmpty ? currentHandle : 'mansi',
            'profileImage': currentUser.photoURL ?? '',
            'isCurrentUser': true,
          });
        }
      }

      // Then search other users from Firestore
      try {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();

        final otherUsers = usersSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .where((user) {
              final username = (user['username'] ?? '')
                  .toString()
                  .toLowerCase();
              final handle = (user['handle'] ?? '').toString().toLowerCase();
              return (username.contains(queryLower) ||
                      handle.contains(queryLower)) &&
                  user['id'] != currentUser?.uid;
            })
            .toList();

        users.addAll(otherUsers);
      } catch (e) {
        debugPrint('Users collection search error: $e');
      }

      userResults = users;
      tweetResults = tweets;
      isLoading = false;
      update();

      _addToRecentSearches(query);
    } catch (e) {
      debugPrint('Search error: $e');
      isLoading = false;
      update();
    }
  }

  void _addToRecentSearches(String query) {
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }
    update();
  }

  void _clearSearch() {
    _searchController.clear();
    isSearching = false;
    searchQuery = '';
    userResults = [];
    tweetResults = [];
    update();
  }
}
