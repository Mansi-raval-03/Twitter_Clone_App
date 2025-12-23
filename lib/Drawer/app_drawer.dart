import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';
import 'package:twitter_clone_app/Pages/book_marks_screen.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/login_screen.dart';
import 'package:twitter_clone_app/Pages/messages_screen.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Pages/search_screen.dart';
import 'package:twitter_clone_app/Pages/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  AppDrawer({super.key});

  final ProfileController _profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),

          _drawerItem(Icons.person, 'Profile', () {
            final uid = _profileController.userProfile.value?.uid ?? '';
            _navigate(
              context,
              ProfileScreen(viewedUserId: uid),
            );
          }),

          _drawerItem(Icons.home, 'Home', () {
            _navigate(
              context,
              HomeScreen(),
            );
          }),

          _drawerItem(Icons.explore, 'Explore', () {
            _navigate(context, const SearchScreen());
          }),

          _drawerItem(Icons.notifications, 'Notifications', () {
            _navigate(context, const NotificationScreen());
          }),

          _drawerItem(Icons.mail, 'Messages', () {
            _navigate(context, const MessagesScreen());
          }),

          _drawerItem(Icons.bookmark, 'Bookmarks', () {
            _navigate(context, BookmarksScreen());
          }),

          const Divider(),

          _drawerItem(Icons.settings, 'Settings & Privacy', () {
            _navigate(context, const SettingsScreen());
          }),

          _drawerItem(Icons.help, 'Help Center', () {}),

          _drawerItem(Icons.logout, 'Logout', () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }),
        ],
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final user = _profileController.userProfile.value;
      final isLoading = _profileController.isLoading.value;

      return DrawerHeader(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: (user != null && user.profileImage.isNotEmpty)
                        ? NetworkImage(user.profileImage)
                        : null,
                    child: (user == null || user.profileImage.isEmpty)
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Guest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user != null && user.username.isNotEmpty ? '@${user.username}' : '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
      );
    });
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
