import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
import 'package:twitter_clone_app/Pages/settings_screen.dart';

import 'package:twitter_clone_app/Widgets/tweet_composer.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});
  final UserProfile currentUser = UserProfile(
    name: "Mansi",
    username: "mansiraval",
     bio: "Building amazing things with Flutter.I’ve learned that growth doesn’t always look like progress. Sometimes it looks like silence, patience, and choosing yourself even when it’s uncomfortable.",
   
    location: "USA",
    email: "mansiraval@gmail.com",
    profileImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQJ3ZD3eQoivQ0xJ4p_ILshOk74FwZ8NS-Kmw&s",
    coverImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSpjRkfdV2CW7Sg2sT7e3zRmUyUUIOh5IW0bw&s",
    posts: 150,
    followers: 250,
    following: 500,
    likes: 10000,
  );
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  // Mock users for random tweets
  final List<Map<String, String>> _mockUsers = [
    {'username': 'John Doe', 'handle': '@johndoe', 'profileImage': 'https://i.pravatar.cc/150?img=1'},
    {'username': 'Sarah Smith', 'handle': '@sarahsmith', 'profileImage': 'https://i.pravatar.cc/150?img=5'},
    {'username': 'Mike Johnson', 'handle': '@mikej', 'profileImage': 'https://i.pravatar.cc/150?img=12'},
    {'username': 'Emily Brown', 'handle': '@emilybrown', 'profileImage': 'https://i.pravatar.cc/150?img=9'},
    {'username': 'David Wilson', 'handle': '@davidw', 'profileImage': 'https://i.pravatar.cc/150?img=15'},
    {'username': 'Lisa Anderson', 'handle': '@lisaanderson', 'profileImage': 'https://i.pravatar.cc/150?img=20'},
    {'username': 'James Taylor', 'handle': '@jamestaylor', 'profileImage': 'https://i.pravatar.cc/150?img=13'},
    {'username': 'Maria Garcia', 'handle': '@mariagarcia', 'profileImage': 'https://i.pravatar.cc/150?img=24'},
    {'username': 'Robert Lee', 'handle': '@robertlee', 'profileImage': 'https://i.pravatar.cc/150?img=33'},
    {'username': 'Jennifer White', 'handle': '@jenniferwhite', 'profileImage': 'https://i.pravatar.cc/150?img=47'},
  ];

  final List<String> _mockTexts = [
    'Everyone has a purpose. You become unstoppable when you figure it out.',
    'Working on a new Flutter feature. It’s coming soon!',
    'Coffee first, code later ☕️',
    'Ship it! #Flutter #Mobile',
    'Reading about state management patterns today.',
    'Small steps, big results.',
    'What’s your favorite Dart trick?',
    'Stay focused, stay humble.',
    'That feeling when CI turns green ✅',
    'New design just dropped!',
  ];

  final List<String> _mockImages = [
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
    'https://images.unsplash.com/photo-1520975661595-6453be3f7070',
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429',
  ];

  List<TweetModel> _buildRandomTweets(int count) {
    final rnd = Random();
    return List.generate(count, (i) {
      final user = _mockUsers[rnd.nextInt(_mockUsers.length)];
      final hasImage = rnd.nextBool();
      return TweetModel(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(99999)}',
        uid: 'uid_${rnd.nextInt(10000)}',
        username: user['username']!,
        handle: user['handle']!,
        profileImage: user['profileImage']!,
        content: _mockTexts[rnd.nextInt(_mockTexts.length)],
        imageUrl: hasImage ? _mockImages[rnd.nextInt(_mockImages.length)] : '',
        likes: List<String>.generate(rnd.nextInt(50), (j) => 'u$j'),
        comments: List<String>.generate(rnd.nextInt(20), (j) => 'c$j'),
        createdAt: DateTime.now().subtract(Duration(minutes: rnd.nextInt(500))),
        isLiked: rnd.nextBool(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
            onPressed: () {
              _navigate(
                context,
                SettingsScreen(),
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: IndexedStack(
        children: [
          Container(
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tweets')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If Firestore has tweets, show them
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final tweets = snapshot.data!.docs
                      .map((doc) => TweetModel.fromDoc(doc))
                      .toList();

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 4, bottom: 96),
                    itemCount: tweets.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (_, index) => TweetCardWidget(tweet: tweets[index]),
                  );
                }

                // Fallback: show random tweets by different users
                final randomTweets = _buildRandomTweets(15);
                return ListView.separated(
                  padding: const EdgeInsets.only(top: 4, bottom: 96),
                  itemCount: randomTweets.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (_, index) => TweetCardWidget(tweet: randomTweets[index]),
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
                      username:
                          FirebaseAuth.instance.currentUser?.displayName ??
                          'Mansi',
                      handle:
                          '@${FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Mansi'}',
                      profileImage:
                          FirebaseAuth.instance.currentUser?.photoURL ?? '',
                      onTweet: () async {
                        // Validate content first
                        final state = composerKey.currentState;
                        final content = contentController.text.trim();

                        if (content.isEmpty &&
                            (state == null || state.imageFile == null)) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please add text or image'),
                            ),
                          );
                          return;
                        }

                        final currentUser = FirebaseAuth.instance.currentUser;
                        debugPrint('Current user: ${currentUser?.email}');
                        debugPrint(
                          'User authenticated: ${currentUser != null}',
                        );

                        if (currentUser == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Authentication required. Please sign in again.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        String imageUrl = '';

                        try {
                          // Upload image if present
                          if (state != null && state.imageFile != null) {
                            debugPrint('Uploading image...');
                            final file = state.imageFile!;
                            final storageRef = FirebaseStorage.instance.ref().child(
                              'tweets/${DateTime.now().millisecondsSinceEpoch}.jpg',
                            );
                            final snapshot = await storageRef.putFile(file);
                            imageUrl = await snapshot.ref.getDownloadURL();
                            debugPrint('Image uploaded: $imageUrl');
                          }

                          // Prepare tweet data
                          final tweetData = {
                            'uid': currentUser.uid,
                            'username': currentUser.displayName ?? 'User',
                            'handle':
                                '@${currentUser.email?.split('@')[0] ?? 'user'}',
                            'content': content,
                            'likes': [],
                            'comments': [],
                            'profileImage':
                                currentUser.photoURL ??
                                'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
                            'imageUrl': imageUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          debugPrint('Posting tweet to Firestore...');
                          final docRef = await FirebaseFirestore.instance
                              .collection('tweets')
                              .add(tweetData);
                          debugPrint(
                            'Tweet posted successfully with ID: ${docRef.id}',
                          );

                          contentController.clear();
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tweet posted!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e, stackTrace) {
                          debugPrint('Error posting tweet: $e');
                          debugPrint('Stack trace: $stackTrace');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
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
