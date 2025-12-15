import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text('Account'),
            onTap: () {
            },
          ),
          ListTile(
            title: Text('Privacy and safety'),
            onTap: () {
            },
          ),
          ListTile(
            title: Text('Notifications'),
            onTap: () {
            },
          ),
          ListTile(
            title: Text('Display and sound'),
            onTap: () {
            },
          ),
          ListTile(
            title: Text('Help Center'),
            onTap: () {
            },
          ),
          ListTile(
            title: Text('About'),
            onTap: () {
            },
          ),
        ],
      ),
    );
  }
}