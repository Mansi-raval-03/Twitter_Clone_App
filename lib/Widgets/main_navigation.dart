import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Pages/explore_screen.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/messages_screen.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    NotificationScreen(),
    MessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home', backgroundColor: Colors.grey),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore', backgroundColor: Colors.grey),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications', backgroundColor: Colors.grey),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Messages', backgroundColor: Colors.grey),
        ],
      ),
    );
  }
}
