import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';

import 'package:twitter_clone_app/Widgets/tweet_composer.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.flutter_dash_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('See the latest Tweets'),
                        SizedBox(height: 4),
                        Text(
                          'Follow people and start the conversation.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

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
                  itemBuilder: (_, index) {
                    return TweetCardWidget(tweet: tweets[index]);
                  },
                );
              },
            ),
          ),
          
        ],
      ),
      floatingActionButton:
           FloatingActionButton(
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
                      username: FirebaseAuth
                              .instance.currentUser?.displayName ??
                          'Mansi',
                      handle:
                          '@${FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Mansi'}',
                      profileImage:
                          FirebaseAuth.instance.currentUser?.photoURL ?? '',
                      onTweet: () async {
                        // Validate content first
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
                        debugPrint('Current user: ${currentUser?.email}');
                        debugPrint('User authenticated: ${currentUser != null}');
                        
                        if (currentUser ==  null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Authentication required. Please sign in again.'),
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
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child('tweets/${DateTime.now().millisecondsSinceEpoch}.jpg');
                            final snapshot = await storageRef.putFile(file);
                            imageUrl = await snapshot.ref.getDownloadURL();
                            debugPrint('Image uploaded: $imageUrl');
                          }

                          // Prepare tweet data
                          final tweetData = {
                            'uid': currentUser.uid,
                            'username': currentUser.displayName ?? 'User',
                            'handle': '@${currentUser.email?.split('@')[0] ?? 'user'}',
                            'content': content,
                            'likes': [],
                            'comments': [],
                            'profileImage': currentUser.photoURL ??
                                'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
                            'imageUrl': imageUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          debugPrint('Posting tweet to Firestore...');
                          final docRef = await FirebaseFirestore.instance
                              .collection('tweets')
                              .add(tweetData);
                          debugPrint('Tweet posted successfully with ID: ${docRef.id}');

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
      )
         
    );
  }
}
