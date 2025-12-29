// using Firestore streams; removed local mock/random data

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/Widgets/tweet_composer.dart';
import 'package:twitter_clone_app/controller/home_conteoller.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use HomeController for all tweet operations
  final HomeController _homeController = Get.put(HomeController());

  // Using real-time tweets from Firestore via HomeController; no local mock data

  

  @override
  void dispose() {
    // Let GetX handle controller lifecycle if needed; dispose other controllers if added
    super.dispose();
  }

  // Cache for user data to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _usersCache = {};

  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    if (_usersCache.containsKey(uid)) {
      return _usersCache[uid];
    }
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _usersCache[uid] = doc.data()!;
        return doc.data();
      }
    } catch (e) {
      print('Error fetching user $uid: $e');
    }
    return null;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersForTweets(List<TweetModel> tweets) async {
    final uniqueUids = tweets.map((t) => t.uid).toSet();
    final usersMap = <String, Map<String, dynamic>>{};
    
    for (final uid in uniqueUids) {
      final userData = await _fetchUserData(uid);
      if (userData != null) {
        usersMap[uid] = userData;
      }
    }
    
    // Also fetch retweeter data if needed
    for (final tweet in tweets) {
      for (final retweetUid in tweet.retweets) {
        if (!usersMap.containsKey(retweetUid)) {
          final userData = await _fetchUserData(retweetUid);
          if (userData != null) {
            usersMap[retweetUid] = userData;
          }
        }
      }
    }
    
    return usersMap;
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
  backgroundColor: Theme.of(context).primaryTextTheme.bodyLarge?.color,
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

        elevation: 0.4,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 56,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Home',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).primaryIconTheme.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      ),

      body: IndexedStack(
        children: [
          Container(
            color:   Theme.of(context).scaffoldBackgroundColor,
          
            // Load tweets stream and enrich with user data on demand
            child: StreamBuilder<List<TweetModel>>(
              stream: _homeController.tweetsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
          
                if (snapshot.hasError) {
                  return Center(child: Text('Tweets load error: ${snapshot.error}'));
                }
          
                final tweets = snapshot.data ?? [];
          
                if (tweets.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No tweets yet. Be the first to post!',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
          
                // Fetch user data for each unique tweet author
                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _fetchUsersForTweets(tweets),
                  builder: (context, usersSnapshot) {
                    final usersMap = usersSnapshot.data ?? {};
          
                    // Enrich tweet author info using usersMap
                    final enrichedTweets = tweets.map((t) {
                      final author = usersMap[t.uid];
                      if (author != null) {
                        final username = (author['username'] ?? author['name'] ?? t.username).toString();
                        String handle = t.handle;
                        if (author['handle'] != null && author['handle'].toString().isNotEmpty) {
                          final h = author['handle'].toString();
                          handle = h.startsWith('@') ? h : '@$h';
                        } else if (author['email'] != null && author['email'].toString().contains('@')) {
                          handle = '@${author['email'].toString().split('@')[0]}';
                        }
                        final profileImage = (author['profileImage'] ?? author['profilePicture'] ?? t.profileImage).toString();
          
                        // Determine a primary retweeter (for display) if available
                        String retweetedBy = '';
                        if (t.retweets.isNotEmpty) {
                          final uid = t.retweets.first;
                          final ru = usersMap[uid];
                          if (ru != null) {
                            retweetedBy = (ru['username'] ?? ru['name'] ?? '').toString();
                          }
                        }
          
                        return TweetModel(
                          id: t.id,
                          uid: t.uid,
                          username: username,
                          handle: handle,
                          profileImage: profileImage,
                          // If this tweet is a retweet, keep original fields on the model
                          content: t.isRetweet ? (t.originalContent.isNotEmpty ? t.originalContent : t.content) : t.content,
                          imageUrl: t.isRetweet ? (t.originalImageUrl.isNotEmpty ? t.originalImageUrl : t.imageUrl) : t.imageUrl,
                          likes: t.likes,
                          retweets: t.retweets,
                          comments: t.comments,
                          createdAt: t.createdAt,
                          isLiked: t.isLiked,
                          retweetedBy: retweetedBy,
                          isRetweet: t.isRetweet,
                          originalTweetId: t.originalTweetId,
                          originalUsername: t.originalUsername,
                          originalHandle: t.originalHandle,
                          originalProfileImage: t.originalProfileImage,
                          originalContent: t.originalContent,
                          originalImageUrl: t.originalImageUrl,
                          originalCreatedAt: t.originalCreatedAt,
                        );
                      }
                      return t;
                    }).toList();
          
                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: enrichedTweets.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      itemBuilder: (_, index) {
                        final tweet = enrichedTweets[index];
                        return GestureDetector(
                          onTap: () {
                           Get.to(() => UserProfileScreen(
                                viewedUserId: tweet.uid,
                            ));
                          },
                          child: TweetCardWidget(tweet: tweet),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        onPressed: () {
          final contentController = TextEditingController();
          final composerKey = GlobalKey<TweetComposerWidgetState>();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (dialogContext) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: TweetComposerWidget(
                      key: composerKey,
                      controller: contentController,
                      username: FirebaseAuth.instance.currentUser?.displayName ?? 'Mansi',
                      handle:
                          '@${FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Mansi'}',
                      profileImage: FirebaseAuth.instance.currentUser?.photoURL ?? '',
                      onTweet: () async {
                        final state = composerKey.currentState;
                        final content = contentController.text.trim();

                        if (content.isEmpty && (state == null || state.imageFile == null)) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add text or image')),
                          );
                          return;
                        }

                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Authentication required. Please sign in again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Delegate post to HomeController which handles image upload & Firestore write
                          await _homeController.postTweet(
                            content: content,
                            imageFile: state?.imageFile,
                          );

                          contentController.clear();
                          if (!dialogContext.mounted) return;
                          Get.back(); // Close the bottom navigator

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tweet posted!'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.create, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}
