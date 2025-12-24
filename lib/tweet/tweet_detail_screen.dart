import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:twitter_clone_app/Pages/user_profile_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/tweet/reply_model.dart';
import 'package:twitter_clone_app/services/tweet_service.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';

class TweetDetailScreen extends StatefulWidget {
  final TweetModel tweet;

  const TweetDetailScreen({super.key, required this.tweet});

  @override
  State<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends State<TweetDetailScreen> {
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    // Check if current user has liked the passed tweet snapshot
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('h:mm a · MMM d, y').format(date);
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tweet'),
        elevation: 0.5,
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tweets').doc(widget.tweet.id).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error loading tweet: ${snap.error}'));

                    final tweetDoc = snap.data;
                    final TweetModel tweet = (tweetDoc != null && tweetDoc.exists) ? TweetModel.fromDoc(tweetDoc) : widget.tweet;

                    // If this document is a retweet, prefer the embedded original fields for display
                    final isRetweet = tweet.isRetweet;
                    final displayUsername = isRetweet ? tweet.originalUsername : tweet.username;
                    final displayHandle = isRetweet ? tweet.originalHandle : tweet.handle;
                    final displayProfileImage = isRetweet ? tweet.originalProfileImage : tweet.profileImage;
                    final displayContent = isRetweet ? tweet.originalContent : tweet.content;
                    final displayImage = isRetweet ? tweet.originalImageUrl : tweet.imageUrl;
                    final displayCreatedAt = isRetweet ? (tweet.originalCreatedAt ?? tweet.createdAt) : tweet.createdAt;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          GestureDetector(
                            onTap: () => Get.to(() => UserProfileScreen(
                                  userName: displayUsername,
                                  userHandle: displayHandle.replaceAll('@', ''),
                                  userBio: '',
                                  profileImageUrl: displayProfileImage,
                                  coverImageUrl: '',
                                  followersCount: 0,
                                  followingCount: 0,
                                  tweetsCount: 0,
                                )),
                            child: _buildAvatar(displayProfileImage, radius: 26),
                          ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                          Text(displayUsername, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(displayHandle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                Text(_formatDate(displayCreatedAt), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(displayContent, style: const TextStyle(fontSize: 18, height: 1.5))),

                          if (displayImage.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: _buildTweetImage(displayImage))),
                            ),

                          const SizedBox(height: 16),
                          const Divider(height: 32),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(children: [
                              _buildStat(tweet.comments.length, 'Replies'),
                              const SizedBox(width: 24),
                              _buildStat(tweet.retweets.length, 'Retweets'),
                              const SizedBox(width: 24),
                              _buildStat(tweet.likes.length, 'Likes'),
                            ]),
                          ),

                          const Divider(height: 32),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildAction(Icons.chat_bubble_outline, tweet.comments.length, _showReplyDialog),
                                _buildAction(
                                  Icons.repeat,
                                  tweet.retweets.length,
                                  () async {
                                    final currentUser = FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to retweet')));
                                      return;
                                    }
                                    try {
                                      final targetId = tweet.isRetweet ? tweet.originalTweetId : tweet.id;
                                      await TweetService.toggleRetweet(targetId, currentUser.uid);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tweet.retweets.contains(currentUser.uid) ? 'Retweet removed' : 'Retweeted!')));
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                  active: tweet.retweets.contains(FirebaseAuth.instance.currentUser?.uid),
                                  color: Colors.green,
                                ),
                                _buildAction(
                                  Icons.favorite,
                                  tweet.likes.length,
                                  () async {
                                    final currentUser = FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to like')));
                                      return;
                                    }
                                    try {
                                      await TweetService.toggleLike(tweet.id, tweet.likes);
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                  active: tweet.likes.contains(FirebaseAuth.instance.currentUser?.uid),
                                  color: Colors.red,
                                ),
                                IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                              ],
                            ),
                          ),

                          const Divider(height: 32),

                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Replies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]))),

                          StreamBuilder<QuerySnapshot>(
                            stream: TweetService.getRepliesStream(tweet.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                              if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text('Error loading replies: ${snapshot.error}'));
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('No replies yet. Be the first to reply!', style: TextStyle(color: Colors.grey[600]))));

                              final replies = snapshot.data!.docs.map((doc) => ReplyModel.fromDoc(doc)).toList();

                              return ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: replies.length, separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]), itemBuilder: (context, index) => _buildReplyItem(replies[index]));
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              );
            }

            void _showReplyDialog() {
              final replyController = TextEditingController();
              final currentUser = FirebaseAuth.instance.currentUser;

              if (currentUser == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to reply')));
                return;
              }

              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reply', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvatar(currentUser.photoURL ?? '', radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(controller: replyController, decoration: InputDecoration(hintText: 'Tweet your reply', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey[600])), maxLines: 4, autofocus: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              final reply = replyController.text.trim();
                              if (reply.isEmpty) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reply')));
                                return;
                              }

                              try {
                                await TweetService.addReply(widget.tweet.id, reply);
                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply posted!')));
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                            child: const Text('Reply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            Widget _buildStat(int count, String label) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_formatNumber(count), style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: Colors.grey[600]))]);
            }

            Widget _buildAction(IconData icon, int count, VoidCallback onTap, {bool active = false, Color color = Colors.blue}) {
              return GestureDetector(onTap: onTap, child: Row(children: [Icon(icon, size: 18, color: active ? color : Colors.grey), const SizedBox(width: 6), Text(count > 0 ? _formatNumber(count) : '', style: TextStyle(color: active ? color : Colors.grey))]));
            }

            Widget _buildReplyItem(ReplyModel reply) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildAvatar(reply.profileImage, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(reply.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(reply.handle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(width: 6),
                        Text('·', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(width: 6),
                        Text(_formatReplyDate(reply.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 14))
                      ]),
                      const SizedBox(height: 4),
                      Text(reply.content, style: const TextStyle(fontSize: 15, height: 1.4))
                    ]),
                  )
                ]),
              );
            }

            String _formatReplyDate(DateTime date) {
              final now = DateTime.now();
              final diff = now.difference(date);

              if (diff.inSeconds < 60) return '${diff.inSeconds}s';
              if (diff.inMinutes < 60) return '${diff.inMinutes}m';
              if (diff.inHours < 24) return '${diff.inHours}h';
              if (diff.inDays < 7) return '${diff.inDays}d';
              return DateFormat('MMM d').format(date);
            }
  
            Widget _buildAvatar(String path, {double radius = 24}) {
              final src = (path).toString().trim();
              if (src.isEmpty) return CircleAvatar(radius: radius, child: Icon(Icons.person, size: radius * 0.8));

              if (src.startsWith('http') || src.startsWith('data:')) {
                final provider = resolveImageProvider(src);
                return CircleAvatar(radius: radius, backgroundImage: provider, child: provider == null ? Icon(Icons.person, size: radius * 0.8) : null);
              }

              return FutureBuilder<String?>(
                future: FirebaseStorage.instance.ref(src).getDownloadURL(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return CircleAvatar(radius: radius, child: Icon(Icons.person, size: radius * 0.8));
                  final url = snap.data;
                  if (url == null || url.isEmpty) return CircleAvatar(radius: radius, child: Icon(Icons.person, size: radius * 0.8));
                  final provider = resolveImageProvider(url);
                  return CircleAvatar(radius: radius, backgroundImage: provider, child: provider == null ? Icon(Icons.person, size: radius * 0.8) : null);
                },
              );
            }

            Widget _buildTweetImage(String src) {
              final s = (src).toString().trim();
              if (s.isEmpty) return Container();
              if (s.startsWith('http') || s.startsWith('data:')) {
                final provider = resolveImageProvider(s);
                if (provider == null) return Container();
                return Image(image: provider, fit: BoxFit.cover);
              }

              return FutureBuilder<String?>(
                future: FirebaseStorage.instance.ref(s).getDownloadURL(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return Container();
                  final url = snap.data;
                  if (url == null || url.isEmpty) return Container();
                  final provider = resolveImageProvider(url);
                  if (provider == null) return Container();
                  return Image(image: provider, fit: BoxFit.cover);
                },
              );
            }
          }
             

