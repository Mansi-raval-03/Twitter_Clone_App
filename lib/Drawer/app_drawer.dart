import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:twitter_clone_app/Pages/follow_list_page.dart';
import 'package:twitter_clone_app/Pages/help_center_screen.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';
import 'package:twitter_clone_app/utils/image_resolver.dart';
import 'package:twitter_clone_app/Pages/book_marks_screen.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/Pages/settings_screen.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';

class AppDrawer extends StatelessWidget {
  AppDrawer({super.key});

  final ProfileController _profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(
            null,
            _profileController.userProfile.value?.uid ?? '',
            context,
          ),

          _drawerItem(Icons.person, 'Profile', () {
            final uid = _profileController.userProfile.value?.uid ?? '';
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  user: '',
                  tweets: [],
                  replies: [],
                  initialIndex: 4,
                  profileUserId: uid,
                ),
              ),
            );
          }),

          _drawerItem(Icons.home, 'Home', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  user: '',
                  tweets: [],
                  replies: [],
                  initialIndex: 0,
                ),
              ),
            );
          }),

          _drawerItem(Icons.explore, 'Explore', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  user: '',
                  tweets: [],
                  replies: [],
                  initialIndex: 1,
                ),
              ),
            );
          }),

          _drawerItem(Icons.notifications, 'Notifications', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  user: '',
                  tweets: [],
                  replies: [],
                  initialIndex: 2,
                ),
              ),
            );
          }),

          _drawerItem(Icons.mail, 'Messages', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  user: '',
                  tweets: [],
                  replies: [],
                  initialIndex: 3,
                ),
              ),
            );
          }),

          _drawerItem(Icons.bookmark, 'Bookmarks', () {
            _navigate(context, BookmarksScreen());
          }),

          const Divider(),

          _drawerItem(Icons.settings, 'Settings & Privacy', () {
            _navigate(context, const SettingsScreen());
          }),

          _drawerItem(Icons.help, 'Help Center', () {
            _navigate(context, const HelpCenterScreen());
          }),

          _drawerItem(Icons.logout, 'Logout', () async {
            // Sign out from GoogleSignIn first so the account chooser appears next time.
            try {
              await GoogleSignIn().signOut();
              // Attempt to fully disconnect (revokes consent) to force account picker.
              await GoogleSignIn().disconnect();
            } catch (_) {}

            // Sign out from Firebase Auth
            await FirebaseAuth.instance.signOut();

            // Remove active notification listener/controller if present
            if (Get.isRegistered<NotificationController>()) {
              try {
                final notif = Get.find<NotificationController>();
                notif.stopListener();
                Get.delete<NotificationController>(force: true);
              } catch (_) {}
            }

            // Navigate to login screen
            Get.offAllNamed(AppRoute.login);
          }),
        ],
      ),
    );
  }

  /// Header
  Widget _buildHeader(
    Map<String, dynamic>? data,
    String uid,
    BuildContext context,
  ) {
    // Use real-time user document so follower/following counts update immediately.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileController.userDocStream(uid).asBroadcastStream(),
      builder: (context, snap) {
        final userDocData = snap.data?.data() ?? data ?? {};
        final isLoading = _profileController.isLoading.value && !snap.hasData;
        final user = _profileController.userProfile.value;
        final displayName = (userDocData['name'] as String?) ?? user?.name ?? 'Guest';
        final displayUsername = (userDocData['username'] as String?) ?? user?.username ?? '';
        final profileImageRaw = (userDocData['profileImage'] ?? userDocData['profilePicture'] ?? user?.profileImage ?? '').toString();
        final followersCount = (userDocData['followers'] ?? user?.followers ?? 0).toString();
        final followingCount = (userDocData['following'] ?? user?.following ?? 0).toString();

        return DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).floatingActionButtonTheme.backgroundColor,
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (ctx) {
                        final trimmed = profileImageRaw.trim();
                        if (trimmed.isEmpty) {
                          return const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32));
                        }
                        if (trimmed.startsWith('http') || trimmed.startsWith('data:')) {
                          final provider = resolveImageProvider(trimmed);
                          return CircleAvatar(radius: 28, backgroundImage: provider, child: provider == null ? const Icon(Icons.person, size: 32) : null);
                        }
                        return FutureBuilder<String?>(
                          future: _profileController.resolveImageUrl(trimmed),
                          builder: (c, s) {
                            if (s.connectionState == ConnectionState.waiting) return const CircleAvatar(radius: 30, child: CircularProgressIndicator());
                            final url = s.data;
                            if (url == null || url.isEmpty) return const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 32));
                            final provider = resolveImageProvider(url);
                            return CircleAvatar(radius: 30, backgroundImage: provider, child: provider == null ? const Icon(Icons.person, size: 32) : null);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MainNavigationScreen(user: '', tweets: [], replies: [], initialIndex: 4, profileUserId: user?.uid ?? '')));
                      },
                      child: Text(displayName, style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MainNavigationScreen(user: '', tweets: [], replies: [], initialIndex: 4, profileUserId: user?.uid ?? '')));
                      },
                      child: Text(displayUsername.isNotEmpty ? '@$displayUsername' : '', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8))),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MainNavigationScreen(user: '', tweets: [], replies: [], initialIndex: 4, profileUserId: user?.uid ?? '')));
                      },
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => FollowListPage(userId: uid, showFollowers: false, title: 'Following'));
                            },
                            child: Text('$followingCount Following', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), fontSize: 14)),
                          ),
                          SizedBox(width: Get.width * 0.03),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => FollowListPage(userId: uid, showFollowers: true, title: 'Followers'));
                            },
                            child: Text('$followersCount Followers', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9), fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Drawer Item
  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  /// Navigation helper
  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
