import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class SearchController extends GetxController implements TickerProvider {

  // Controller for search input field
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final List<Ticker> _tickers = [];
  List<String> recentSearches = [];
  bool isSearching = false;
  String searchQuery = '';

  List<Map<String, dynamic>> userResults = [];
  List<TweetModel> tweetResults = [];
  bool isLoading = false;


  // Initialize tab controller
  @override
  void onInit() {
    super.onInit();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Create ticker for animations
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


  
}
