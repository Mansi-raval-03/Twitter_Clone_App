import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          'Help Center',
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
          _buildSectionHeader(context, 'Getting Started'),
          _buildHelpItem(
            context,
            icon: Icons.account_circle,
            title: 'Creating an Account',
            description: 'Learn how to sign up and set up your profile',
            onTap: () => _showHelpDetail(
              context,
              'Creating an Account',
              'To create an account:\n\n'
                  '1. Tap "Sign Up" on the login screen\n'
                  '2. Enter your email address\n'
                  '3. Create a secure password\n'
                  '4. Verify your email\n'
                  '5. Complete your profile with a username and bio\n\n'
                  'Your account is now ready to use!',
            ),
          ),
          _buildHelpItem(
            context,
            icon: Icons.edit,
            title: 'Posting Tweets',
            description: 'How to share your thoughts and media',
            onTap: () => _showHelpDetail(
              context,
              'Posting Tweets',
              'To post a tweet:\n\n'
                  '1. Tap the + button at the bottom\n'
                  '2. Type your message (up to 280 characters)\n'
                  '3. Optionally add photos by tapping the image icon\n'
                  '4. Tap "Tweet" to post\n\n'
                  'Your tweet will appear on your profile and in your followers\' feeds.',
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Features'),
          _buildHelpItem(
            context,
            icon: Icons.favorite,
            title: 'Likes and Retweets',
            description: 'Interact with tweets you enjoy',
            onTap: () => _showHelpDetail(
              context,
              'Likes and Retweets',
              'Engage with content:\n\n'
                  '• Like: Tap the heart icon to show appreciation\n'
                  '• Retweet: Share tweets to your followers\n'
                  '• Comment: Reply to tweets and join conversations\n'
                  '• Bookmark: Save tweets to read later\n\n'
                  'All your interactions are visible on your profile.',
            ),
          ),
          _buildHelpItem(
            context,
            icon: Icons.people,
            title: 'Following Users',
            description: 'Connect with people and see their updates',
            onTap: () => _showHelpDetail(
              context,
              'Following Users',
              'To follow someone:\n\n'
                  '1. Visit their profile\n'
                  '2. Tap the "Follow" button\n'
                  '3. Their tweets will appear in your home feed\n\n'
                  'To unfollow, tap "Following" on their profile.\n\n'
                  'View your followers and following lists from your profile.',
            ),
          ),
          _buildHelpItem(
            context,
            icon: Icons.message,
            title: 'Direct Messages',
            description: 'Send private messages to other users',
            onTap: () => _showHelpDetail(
              context,
              'Direct Messages',
              'Send private messages:\n\n'
                  '1. Go to Messages tab\n'
                  '2. Tap the compose icon\n'
                  '3. Search for a user\n'
                  '4. Start chatting!\n\n'
                  'Messages are private and only visible to you and the recipient.',
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Privacy & Settings'),
          _buildHelpItem(
            context,
            icon: Icons.lock,
            title: 'Privacy Settings',
            description: 'Control who can see your content',
            onTap: () => _showHelpDetail(
              context,
              'Privacy Settings',
              'Manage your privacy:\n\n'
                  '• Private Account: Only approved followers can see your tweets\n'
                  '• Push Notifications: Control app notifications\n'
                  '• Email Notifications: Manage email alerts\n\n'
                  'Access settings from the drawer menu → Settings & Privacy.',
            ),
          ),
          _buildHelpItem(
            context,
            icon: Icons.edit_note,
            title: 'Edit Profile',
            description: 'Update your profile information',
            onTap: () => _showHelpDetail(
              context,
              'Edit Profile',
              'Update your profile:\n\n'
                  '1. Go to your profile\n'
                  '2. Tap "Edit Profile"\n'
                  '3. Change your profile picture, cover photo, bio, or location\n'
                  '4. Tap "Save" when done\n\n'
                  'Your updated profile will be visible to all users.',
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Account Management'),
          _buildHelpItem(
            context,
            icon: Icons.password,
            title: 'Reset Password',
            description: 'Change or recover your password',
            onTap: () => _showHelpDetail(
              context,
              'Reset Password',
              'To reset your password:\n\n'
                  '1. Tap "Forgot Password" on login screen\n'
                  '2. Enter your registered email\n'
                  '3. Check your email for reset link\n'
                  '4. Follow the link to create a new password\n\n'
                  'Keep your password secure and don\'t share it with anyone.',
            ),
          ),
          _buildHelpItem(
            context,
            icon: Icons.delete_forever,
            title: 'Account Deletion',
            description: 'Permanently delete your account',
            onTap: () => _showHelpDetail(
              context,
              'Account Deletion',
              'To delete your account:\n\n'
                  '⚠️ Warning: This action is permanent and cannot be undone.\n\n'
                  '1. Go to Settings & Privacy\n'
                  '2. Scroll to "Account"\n'
                  '3. Select "Delete Account"\n'
                  '4. Confirm your decision\n\n'
                  'All your tweets, followers, and data will be permanently removed.',
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Contact & Support'),
          _buildHelpItem(
            context,
            icon: Icons.email,
            title: 'Contact Support',
            description: 'Get help from our support team',
            onTap: () => _launchEmail(),
          ),
          _buildHelpItem(
            context,
            icon: Icons.bug_report,
            title: 'Report a Bug',
            description: 'Help us improve by reporting issues',
            onTap: () => _launchEmail(subject: 'Bug Report'),
          ),
          _buildHelpItem(
            context,
            icon: Icons.info,
            title: 'About',
            description: 'App version and legal information',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isDark
            ? BorderSide(color: Colors.grey.shade800, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).iconTheme.color,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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

  void _showHelpDetail(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail({String subject = 'Support Request'}) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      query: 'subject=$subject',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        Get.snackbar(
          'Cannot Open',
          'No email app found on your device',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open email app',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Twitter Clone',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Twitter Clone App\nAll rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'A modern social media application built with Flutter.\n\n'
          'Features:\n'
          '• Post tweets with text and images\n'
          '• Follow users and build your network\n'
          '• Like, comment, and retweet\n'
          '• Direct messaging\n'
          '• Dark mode support\n'
          '• And much more!',
        ),
      ],
    );
  }
}
