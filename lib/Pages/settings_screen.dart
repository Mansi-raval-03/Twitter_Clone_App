import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twitter_clone_app/Pages/edit_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  void _openAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Not signed in', 'Please sign in to edit your profile');
      return;
    }

    Get.to(
      () => MainNavigationScreen(
        user: '',
        tweets: [],
        replies: [],
        initialIndex: 4,
        profileUserId: uid,
      ),
    );
  }

  void _showPrivacyDialog() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Not signed in', 'Please sign in to change privacy');
      return;
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    bool isPrivate = (doc.data()?['isPrivate'] ?? false) as bool;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Privacy and safety'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Private account')),
                Switch(
                  value: isPrivate,
                  onChanged: (v) async {
                    setStateDialog(() => isPrivate = v);
                    await _firestore.collection('users').doc(uid).set({
                      'isPrivate': v,
                    }, SetOptions(merge: true));
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotificationsDialog() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Not signed in', 'Please sign in to change notifications');
      return;
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    bool push = (doc.data()?['pushNotifications'] ?? true) as bool;
    bool email = (doc.data()?['emailNotifications'] ?? false) as bool;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Notifications'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Push notifications'),
                  value: push,
                  onChanged: (v) async {
                    setStateDialog(() => push = v);
                    await _firestore.collection('users').doc(uid).set({
                      'pushNotifications': v,
                    }, SetOptions(merge: true));
                  },
                ),
                SwitchListTile(
                  title: const Text('Email notifications'),
                  value: email,
                  onChanged: (v) async {
                    setStateDialog(() => email = v);
                    await _firestore.collection('users').doc(uid).set({
                      'emailNotifications': v,
                    }, SetOptions(merge: true));
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDisplayDialog() async {
    final current = Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Display & Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (v) {
                if (v == null) return;
                Get.changeThemeMode(v);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (v) {
                if (v == null) return;
                Get.changeThemeMode(v);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (v) {
                if (v == null) return;
                Get.changeThemeMode(v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openHelpCenter() async {
    const url = 'https://support.example.com';
    if (!await canLaunchUrl(Uri.parse(url))) {
      Get.snackbar('Cannot open', url);
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Twitter Clone',
      applicationVersion: '1.0.0',
      applicationLegalese: '© Your Name',
      children: [const Text('A simple Twitter-like demo app.')],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(title: const Text('Account'), onTap: _openAccount),
          ListTile(
            title: const Text('Privacy and safety'),
            onTap: _showPrivacyDialog,
          ),
          ListTile(
            title: const Text('Notifications'),
            onTap: _showNotificationsDialog,
          ),
          ListTile(
            title: const Text('Display and sound'),
            onTap: _showDisplayDialog,
          ),
          ListTile(title: const Text('Help Center'), onTap: _openHelpCenter),
          ListTile(title: const Text('About'), onTap: _showAbout),
        ],
      ),
    );
  }
}
