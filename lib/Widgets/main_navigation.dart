import 'package:flutter/material.dart';
import 'package:twitter_clone_app/Model/user_profile_model.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/messages_screen.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Pages/search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final dynamic user;
  final List<dynamic> tweets;
  final List<dynamic> replies;

   MainNavigationScreen({
    super.key,
    required this.user,
    required this.tweets,
    required this.replies,
  });
final UserProfile currentUser = UserProfile(
    name: "Mansi",
    username: "mansiraval",
     bio: "Building amazing things with Flutter.\nI’ve learned that growth doesn’t always look \nlike progress. Sometimes it looks like silence, \npatience, and choosing yourself even when \nit’s uncomfortable.",
   location: "USA",
    email: "mansiraval@gmail.com",
    profileImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQJ3ZD3eQoivQ0xJ4p_ILshOk74FwZ8NS-Kmw&s",
    coverImage:
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSpjRkfdV2CW7Sg2sT7e3zRmUyUUIOh5IW0bw&s",
    posts: 150,
    followers: 250,
    following: 500,
    likes: 10000,
  );
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
      ProfileScreen(user: widget.currentUser, tweets: [], replies: []),
    ];
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explore',
            backgroundColor: Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
            backgroundColor: Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: 'Messages',
            backgroundColor: Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}
