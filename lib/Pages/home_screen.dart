import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Drawer/app_drawer.dart';
import 'package:twitter_clone_app/Widgets/tweet_composer.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: AppDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tweets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tweets yet'));
          }

          final tweets = snapshot.data!.docs
              .map((doc) => TweetModel.fromDoc(doc))
              .toList();

          return ListView.builder(
            itemCount: tweets.length,
            itemBuilder: (_, index) {
              return TweetCardWidget(tweet: tweets[index]);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              TextEditingController contentController = TextEditingController();
              final composerKey = GlobalKey<TweetComposerWidgetState>();

              return AlertDialog(
                title: const Text('Create a Tweet'),
                content: SingleChildScrollView(
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
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      String imageUrl = '';
                      final state = composerKey.currentState;
                      if (state != null && state.imageFile != null) {
                        final file = state.imageFile!;
                        try {
                          final storageRef = FirebaseStorage.instance.ref().child(
                            'tweets/${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );

                          final uploadTask = storageRef.putFile(file);
                          final snapshot = await uploadTask; // Wait for upload
                          imageUrl = await snapshot.ref.getDownloadURL();
                        } catch (e) {
                          debugPrint('Error uploading image: $e');
                        }
                      }

                      await FirebaseFirestore.instance
                          .collection('tweets')
                          .add({
                            'uid': user.uid,
                            'username': user.displayName ?? 'User',
                            'handle': '@${user.email!.split('@')[0]}',
                            'content': contentController.text,
                            'likes': [],
                            'comments': [],
                            'profileImage': user.photoURL ?? 'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
                            'imageUrl': imageUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
