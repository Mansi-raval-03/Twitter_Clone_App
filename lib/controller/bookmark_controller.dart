import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class BookmarkController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = false.obs;
  final RxList<String> bookmarkIds = <String>[].obs;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Toggle bookmark for a tweet
  Future<void> toggleBookmark(String tweetId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final bookmarkRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(tweetId);

      final bookmarkDoc = await bookmarkRef.get();

      if (bookmarkDoc.exists) {
        // Remove bookmark
        await bookmarkRef.delete();
        Get.snackbar('Success', 'Bookmark removed',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        // Add bookmark
        await bookmarkRef.set({
          'tweetId': tweetId,
          'bookmarkedAt': FieldValue.serverTimestamp(),
        });
        Get.snackbar('Success', 'Tweet bookmarked',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update bookmark: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Check if a tweet is bookmarked
  Future<bool> isBookmarked(String tweetId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final bookmarkDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .doc(tweetId)
          .get();

      return bookmarkDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get bookmarks stream
  Stream<QuerySnapshot> getBookmarksStream() {
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots();
  }

  // Get tweet by ID
  Future<DocumentSnapshot?> getTweetById(String tweetId) async {
    try {
      final tweetDoc = await _firestore
          .collection('tweets')
          .doc(tweetId)
          .get();
      return tweetDoc;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load tweet: $e',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  // Get bookmarks with tweet data
  Future<List<TweetModel>> getBookmarksWithTweets(List<QueryDocumentSnapshot> bookmarks) async {
    List<TweetModel> tweets = [];
    
    for (var bookmark in bookmarks) {
      final bookmarkData = bookmark.data() as Map<String, dynamic>;
      final tweetId = bookmarkData['tweetId'] as String;
      
      final tweetDoc = await getTweetById(tweetId);
      if (tweetDoc != null && tweetDoc.exists) {
        tweets.add(TweetModel.fromDoc(tweetDoc));
      }
    }
    
    return tweets;
  }

  // Remove all bookmarks
  Future<void> clearAllBookmarks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final bookmarks = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bookmarks')
          .get();

      for (var doc in bookmarks.docs) {
        await doc.reference.delete();
      }

      Get.snackbar('Success', 'All bookmarks cleared',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear bookmarks: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

    AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading: BackButton(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: Text(
        'Bookmarks',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget buildNotLoggedInView(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: const Center(
        child: Text('Please log in to view bookmarks'),
      ),
    );
  }

  Widget buildBookmarksList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getBookmarksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorView(context, snapshot.error.toString());
        }

        final bookmarks = snapshot.data?.docs ?? [];

        if (bookmarks.isEmpty) {
          return _buildEmptyState(context);
        }

        return buildBookmarksListView(context, bookmarks);
      },
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Text('Error: $error'),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.color
                ?.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on tweets to save them here',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color
                  ?.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildBookmarksListView(
    BuildContext context,
    List<QueryDocumentSnapshot> bookmarks,
  ) {
    return ListView.separated(
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      ),
      itemBuilder: (context, index) => buildBookmarkItem(context, bookmarks[index]),
    );
  }

  Widget buildBookmarkItem(
    BuildContext context,
    QueryDocumentSnapshot bookmark,
  ) {
    final bookmarkData = bookmark.data() as Map<String, dynamic>;
    final tweetId = bookmarkData['tweetId'] as String;

    return FutureBuilder<DocumentSnapshot?>(
      future: getTweetById(tweetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildLoadingItem();
        }

        if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final tweet = TweetModel.fromDoc(snapshot.data!);
        return buildTweetCard(tweet);
      },
    );
  }

  Widget buildLoadingItem() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildTweetCard(TweetModel tweet) {
    return GestureDetector(
      onTap: () => navigateToUserProfile(tweet.uid),
      child: TweetCardWidget(
        tweet: tweet,
        isBookmarkScreen: true,
      ),
    );
  }

  void navigateToUserProfile(String userId) {
    Get.to(() => UserProfileScreen(viewedUserId: userId));
  }
}
