import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
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

  final UserProfile currentUser = UserProfile(
    name: "Mansi",
    username: "mansiraval",   
    bio: "Building amazing things with Flutter.I’ve learned that growth doesn’t always look like progress. Sometimes it looks like silence, patience, and choosing yourself even when it’s uncomfortable.",
    location: "USA",
    email: "mansiraval@gmail.com",
    profileImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQJ3ZD3eQoivQ0xJ4p_ILshOk74FwZ8NS-Kmw&s",
    coverImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdX029ohIUSygq9zirl9fSNBwSLqEOaKEYuw&s",
    posts: 150,
    followers: 2500000,
    following: 500,
    likes: 10000,
  );

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),

          _drawerItem(Icons.person, 'Profile', () {
            _navigate(
              context,
              ProfileScreen(user: currentUser, tweets: [], replies: []),
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
  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(currentUser.profileImage),
          ),
          const SizedBox(height: 12),
          Text(
            currentUser.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@${currentUser.username}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
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
