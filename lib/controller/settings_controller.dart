import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/help_center_screen.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';

class SettingsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  void openAccount() async {
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

  void showPrivacyDialog() async {

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Not signed in', 'Please sign in to change privacy');
      return;
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    bool isPrivate = (doc.data()?['isPrivate'] ?? false) as bool;

    showDialog(
      context: Get.context!,
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

  void showNotificationsDialog() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Not signed in', 'Please sign in to change notifications');
      return;
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    bool push = (doc.data()?['pushNotifications'] ?? true) as bool;
    bool email = (doc.data()?['emailNotifications'] ?? false) as bool;

    showDialog(
      context: Get.context!,
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

  void showDisplayDialog() async {
    final current = Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    showDialog(
      context: Get.context!,
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

  void openHelpCenter() {
    Get.to(() => const HelpCenterScreen());
  }

  void showAbout() {
    showAboutDialog(
      context: Get.context!,
      applicationName: 'Twitter Clone',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Twitter Clone App',
    );
  }
}
