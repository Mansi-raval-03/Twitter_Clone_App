import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';
import 'package:twitter_clone_app/tweet/tweet_card.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId; // optional: prefer realtime lookup by uid
  final String userName;
  final String userHandle;
  final String userBio;
  final String profileImageUrl;
  final String coverImageUrl;
  final int followersCount;
  final int followingCount;
  final int tweetsCount;

  const UserProfileScreen({
    super.key,
    this.userId,
    required this.userName,
    required this.userHandle,
    required this.userBio,
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.followersCount,
    required this.followingCount,
    required this.tweetsCount,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool? _isFollowing;
  bool _busy = false;
  Stream<Map<String, dynamic>?> _userDataStream() {
    final users = FirebaseFirestore.instance.collection('users');
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      return users.doc(widget.userId).snapshots().map((doc) => doc.exists ? doc.data() : null);
    }
    // fallback: query by handle (useful when navigation passed handle but not uid)
    return users.where('handle', isEqualTo: widget.userHandle).limit(1).snapshots().map((qs) {
      if (qs.docs.isNotEmpty) return qs.docs.first.data();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _userDataStream(),
      builder: (context, snap) {
        final fb = snap.data;

        // derive display values: prefer firestore realtime data, fall back to passed values
        final displayName = (fb?['name'] as String?)?.trim().isNotEmpty == true ? fb!['name'] as String : widget.userName;
        final displayHandle = (fb?['handle'] as String?)?.trim().isNotEmpty == true ? fb!['handle'] as String : widget.userHandle;
        final displayBio = (fb?['bio'] as String?)?.trim().isNotEmpty == true ? fb!['bio'] as String : (widget.userBio.isNotEmpty ? widget.userBio : 'No bio available');
        final displayProfileImage = (fb?['profileImage'] as String?)?.trim().isNotEmpty == true
            ? fb!['profileImage'] as String
            : ((fb?['profilePicture'] as String?)?.trim().isNotEmpty == true ? fb!['profilePicture'] as String : widget.profileImageUrl);
        final displayCoverImage = (fb?['coverImage'] as String?)?.trim().isNotEmpty == true ? fb!['coverImage'] as String : widget.coverImageUrl;
        int displayFollowers = _toIntSafe(fb?['followers']) ?? widget.followersCount;
        int displayFollowing = _toIntSafe(fb?['following']) ?? widget.followingCount;
        int displayTweets = _toIntSafe(fb?['posts']) ?? _toIntSafe(fb?['tweets']) ?? widget.tweetsCount;

        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final targetUid = (fb?['uid'] as String?) ?? widget.userId ?? '';

        // Determine server-side following (if followers list exists)
        bool serverFollowing = false;
        try {
          final list = fb?['followersList'];
          if (list is List && currentUid != null) serverFollowing = list.contains(currentUid);
        } catch (_) {}

        // Sync local state with server state without calling setState during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_isFollowing == null) {
            setState(() => _isFollowing = serverFollowing);
            return;
          }
          if (!_busy && _isFollowing != serverFollowing) {
            setState(() => _isFollowing = serverFollowing);
          }
        });

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover + avatar stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: displayCoverImage.isNotEmpty
                          ? (displayCoverImage.trim().startsWith('http') || displayCoverImage.trim().startsWith('data:')
                              ? Image(image: resolveImageProvider(displayCoverImage) ?? const AssetImage('assets/placeholder.png') as ImageProvider, fit: BoxFit.cover, width: double.infinity)
                              : FutureBuilder<String?>(
                                  future: FirebaseStorage.instance.ref(displayCoverImage).getDownloadURL(),
                                  builder: (context, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) return Container(color: Colors.grey[300]);
                                    final url = snap.data;
                                    if (url == null || url.isEmpty) return Container(color: Colors.grey[300]);
                                    return Image(image: resolveImageProvider(url)!, fit: BoxFit.cover, width: double.infinity);
                                  },
                                ))
                          : Container(color: Colors.grey.shade200),
                    ),
                    Positioned(
                      left: 16,
                      bottom: -40,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(64), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: displayProfileImage.isEmpty
                            ? const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40))
                            : (displayProfileImage.trim().startsWith('http') || displayProfileImage.trim().startsWith('data:')
                                ? CircleAvatar(radius: 48, backgroundImage: resolveImageProvider(displayProfileImage), child: resolveImageProvider(displayProfileImage) == null ? const Icon(Icons.person, size: 40) : null)
                                : FutureBuilder<String?>(
                                    future: FirebaseStorage.instance.ref(displayProfileImage).getDownloadURL(),
                                    builder: (context, snap) {
                                      if (snap.connectionState == ConnectionState.waiting) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
                                      final url = snap.data;
                                      if (url == null || url.isEmpty) return const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 40));
                                      return CircleAvatar(radius: 48, backgroundImage: resolveImageProvider(url), child: resolveImageProvider(url) == null ? const Icon(Icons.person, size: 40) : null);
                                    },
                                  )),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 56),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('@$displayHandle', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (currentUid != null && currentUid == targetUid)
                            OutlinedButton(onPressed: () {}, child: const Text('Edit Profile'))
                          else
                            SizedBox(
                              height: 40,
                              child: _busy
                                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                                  : ElevatedButton(
                                      onPressed: (currentUid == null || targetUid.isEmpty) ? null : () => _toggleFollow(currentUid, targetUid),
                                      style: ElevatedButton.styleFrom(backgroundColor: _isFollowing == true ? Colors.white : Colors.blue, side: _isFollowing == true ? BorderSide(color: Colors.grey.shade300) : null),
                                      child: Text(_isFollowing == true ? 'Following' : 'Follow', style: TextStyle(color: _isFollowing == true ? Colors.black : Colors.white)),
                                    ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (displayBio.isNotEmpty) Text(displayBio, style: const TextStyle(fontSize: 15)),

                      const SizedBox(height: 12),

                      Row(children: [
                        _buildStat('Following', displayFollowing),
                        const SizedBox(width: 24),
                        _buildStat('Followers', displayFollowers),
                        const SizedBox(width: 24),
                        _buildStat('Tweets', displayTweets),
                      ]),

                      const SizedBox(height: 16),
                      const Divider(),

                      /// Tabs
                      _buildTabBar(),

                      const SizedBox(height: 16),

                      // Live tweets for this user
                      if (targetUid.isEmpty)
                        const Center(child: Text('No user selected'))
                      else
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tweets')
                              .where('uid', isEqualTo: targetUid)
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (c, s) {
                            if (s.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text('Error loading tweets: ${s.error}'));
                            if (s.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                            final docs = s.data?.docs ?? [];
                            if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No tweets')));
                            final tweets = docs.map((d) => TweetModel.fromDoc(d)).toList();
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tweets.length,
                              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                              itemBuilder: (_, i) => TweetCardWidget(tweet: tweets[i]),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  int? _toIntSafe(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _ProfileTab(label: 'Tweets', isActive: true),
        _ProfileTab(label: 'Replies'),
        _ProfileTab(label: 'Media'),
        _ProfileTab(label: 'Likes'),
      ],
    );
  }

  Future<void> _toggleFollow(String meId, String targetId) async {
    setState(() => _busy = true);
    final targetRef = FirebaseFirestore.instance.collection('users').doc(targetId);
    final meRef = FirebaseFirestore.instance.collection('users').doc(meId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final tSnap = await tx.get(targetRef);

        final tData = tSnap.data() ?? {};

        final List tFollowers = (tData['followersList'] is List) ? List.from(tData['followersList']) : [];

        final currentlyFollowing = tFollowers.contains(meId);

        if (currentlyFollowing) {
          tx.update(targetRef, {
            'followersList': FieldValue.arrayRemove([meId]),
            'followers': FieldValue.increment(-1),
          });
          tx.update(meRef, {
            'followingList': FieldValue.arrayRemove([targetId]),
            'following': FieldValue.increment(-1),
          });
          setState(() => _isFollowing = false);
        } else {
          tx.update(targetRef, {
            'followersList': FieldValue.arrayUnion([meId]),
            'followers': FieldValue.increment(1),
          });
          tx.update(meRef, {
            'followingList': FieldValue.arrayUnion([targetId]),
            'following': FieldValue.increment(1),
          });
          setState(() => _isFollowing = true);
        }
      });
    } catch (e) {
      debugPrint('Follow toggle failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ProfileTab extends StatelessWidget {
  final String label;
  final bool isActive;

  const _ProfileTab({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        Container(
          height: 2,
          width: 40,
          color: isActive ? Colors.blue : Colors.transparent,
        ),
      ],
    );
  }
}
