// using Firestore streams; removed local mock/random data

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Pages/settings_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    // Users stream from Firestore -> map uid -> user data
    final usersCollection = FirebaseFirestore.instance.collection('users').snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
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
            'Home',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () => Get.to(() => SettingsScreen()),
          ),
        ],
      ),
      body: IndexedStack(
        children: [
          Container(
            color: Colors.white,
            // First listen to users to build a uid->user map, then tweets stream and enrich tweets
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersCollection,
              builder: (context, usersSnap) {
                if (usersSnap.hasError) {
                  return Center(child: Text('Users load error: ${usersSnap.error}'));
                }

                // Build users map (uid -> user map)
                final Map<String, Map<String, dynamic>> usersMap = {};
                final userDocs = usersSnap.data?.docs ?? [];
                for (final doc in userDocs) {
                  usersMap[doc.id] = doc.data();
                }

                return StreamBuilder<List<TweetModel>>(
                  stream: _homeController.tweetsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Tweets load error: ${snapshot.error}'));
                    }

                    final tweets = snapshot.data ?? [];

                    // Enrich tweet author info using usersMap (if available)
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
                          content: t.content,
                          imageUrl: t.imageUrl,
                          likes: t.likes,
                          comments: t.comments,
                          createdAt: t.createdAt,
                          isLiked: t.isLiked,
                          retweetedBy: retweetedBy,
                        );
                      }
                      return t;
                    }).toList();

                    if (enrichedTweets.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No tweets yet. Be the first to post!',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: enrichedTweets.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (_, index) {
                        final tweet = enrichedTweets[index];
                        return GestureDetector(
                          onTap: () {
                           Get.to(() => UserProfileScreen(
                              userName: tweet.username,
                              userHandle: tweet.handle,
                              userBio: '',
                              profileImageUrl: tweet.profileImage,
                              coverImageUrl: '',
                              followersCount: 0,
                              followingCount: 0,
                              tweetsCount: 0,
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
        backgroundColor: Colors.lightBlueAccent,
        shape: const CircleBorder(),
        onPressed: () {
          final contentController = TextEditingController();
          final composerKey = GlobalKey<TweetComposerWidgetState>();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
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
        child: const Icon(Icons.create, color: Colors.white),
      ),
    );
  }
}
