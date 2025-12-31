import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildListTile(context, 'Account', _controller.openAccount),
          _buildListTile(context, 'Privacy and safety', _controller.showPrivacyDialog),
          _buildListTile(context, 'Notifications', _controller.showNotificationsDialog),
          _buildListTile(context, 'Display and sound', _controller.showDisplayDialog),
          _buildListTile(context, 'Help Center', _controller.openHelpCenter),
          _buildListTile(context, 'About', _controller.showAbout),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: isDark ? const Color(0xFF1C1C1C) : Colors.grey[100],
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isDark 
            ? BorderSide(color: Colors.grey.shade800, width: 1) 
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade700,
        ),
        onTap: onTap,
      ),
    );
  }
}
