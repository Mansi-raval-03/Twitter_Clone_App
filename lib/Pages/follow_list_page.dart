import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/services/database_services.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';

class FollowListPage extends StatefulWidget {
  final String userId;
  final bool showFollowers; // true => followers, false => following
  final String title;

  const FollowListPage({Key? key, required this.userId, required this.showFollowers, required this.title}) : super(key: key);

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  final ProfileController _profileCtrl = Get.find();
  String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final stream = widget.showFollowers
        ? DatabaseServices.followersStream(widget.userId)
        : DatabaseServices.followingStream(widget.userId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No users'));

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final uid = data['uid']?.toString() ?? '';
              final name = data['name'] ?? '';
              final username = data['username'] ?? '';
              final profileImage = data['profileImage'] ?? '';

              return ListTile(
                leading: CircleAvatar(backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null, child: profileImage.isEmpty ? const Icon(Icons.person) : null),
                title: Text(name),
                subtitle: Text('@$username'),
                trailing: _currentUid == null || _currentUid == uid
                    ? null
                    : FutureBuilder<bool>(
                        future: DatabaseServices.isFollowing(_currentUid!, uid),
                        builder: (c, s) {
                          final following = s.data ?? false;
                          return OutlinedButton(
                            onPressed: () async {
                              if (_currentUid == null) return;
                              if (following) {
                                await DatabaseServices.unfollowUser(_currentUid!, uid);
                              } else {
                                final curData = _profileCtrl.userProfile.value;
                                final curMap = {
                                  'uid': curData?.uid ?? _currentUid,
                                  'username': curData?.username ?? '',
                                  'name': curData?.name ?? '',
                                  'profileImage': curData?.profileImage ?? '',
                                };
                                final targetMap = {
                                  'uid': uid,
                                  'username': username,
                                  'name': name,
                                  'profileImage': profileImage,
                                };
                                await DatabaseServices.followUser(_currentUid!, curMap, uid, targetMap);
                              }
                              setState(() {});
                            },
                            child: Text(following ? 'Following' : 'Follow'),
                          );
                        },
                      ),
                onTap: () {
                  // Optionally navigate to a profile screen -- left for later
                },
              );
            },
          );
        },
      ),
    );
  }
}
