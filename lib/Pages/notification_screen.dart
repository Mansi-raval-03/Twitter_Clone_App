import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Notifications'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text('User1 liked your tweet'),
            subtitle: Text('2m ago'),
          ),
          ListTile(
            leading: Icon(Icons.comment),
            title: Text('User2 commented on your tweet'),
            subtitle: Text('10m ago'),
          ),
          ListTile(
            leading: Icon(Icons.follow_the_signs),
            title: Text('User3 started following you'),
            subtitle: Text('30m ago'),
          ),
        ],
      ),
    );
  }
}