import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/messages_screen.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Pages/search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final dynamic user;
  final List<dynamic> tweets;
  final List<dynamic> replies;
  final int initialIndex;
  final String? profileUserId;

  MainNavigationScreen({
    super.key,
    required this.user,
    required this.tweets,
    required this.replies,
    this.initialIndex = 0,
    this.profileUserId,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      const SearchScreen(),
      const NotificationScreen(),
      const MessagesScreen(),
      ProfileScreen(viewedUserId: widget.profileUserId ?? ''),
    ];
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.shifting,

        selectedItemColor: Theme.of(context).textTheme.bodyLarge?.color,
        unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color,
        items:  [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home', backgroundColor: Theme.of(context).bottomAppBarTheme.color),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore', backgroundColor: Theme.of(context).bottomAppBarTheme.color),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications', backgroundColor: Theme.of(context).bottomAppBarTheme.color),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Messages', backgroundColor: Theme.of(context).bottomAppBarTheme.color),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile', backgroundColor: Theme.of(context).bottomAppBarTheme.color),
        ],
      ),
    );
  }
}
