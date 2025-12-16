import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userHandle;
  final String userBio;
  final String profileImageUrl;
  final String coverImageUrl;
  final int followersCount;
  final int followingCount;
  final int tweetsCount;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.userHandle,
    required this.userBio,
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.followersCount,
    required this.followingCount,
    required this.tweetsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Cover Image
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: coverImageUrl.isNotEmpty
                  ? Image.network(
                      coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[300]),
                    )
                  : Container(color: Colors.grey[300]),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  /// Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  /// Name
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  /// Handle
                  Text(
                    '@$userHandle',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Bio
                  Text(
                    userBio.isNotEmpty ? userBio : 'No bio available',
                    style: const TextStyle(fontSize: 15),
                  ),

                  const SizedBox(height: 16),

                  /// Stats
                  Row(
                    children: [
                      _buildStat('Following', followingCount),
                      const SizedBox(width: 24),
                      _buildStat('Followers', followersCount),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// Follow Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Follow'),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  /// Tabs (FIXED)
                  _buildTabBar(),

                  const SizedBox(height: 16),

                  _buildTweetsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  /// ✅ FIXED TAB BAR
  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _ProfileTab(label: 'Tweets', isActive: true),
        _ProfileTab(label: 'Replies'),
        _ProfileTab(label: 'Media'),
        _ProfileTab(label: 'Likes'),
      ],
    );
  }

  Widget _buildTweetsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tweetsCount,
      itemBuilder: (_, __) => const Divider(height: 24),
    );
  }
}

/// ✅ NO Expanded here anymore
class _ProfileTab extends StatelessWidget {
  final String label;
  final bool isActive;

  const _ProfileTab({
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        Container(
          height: 2,
          width: 40,
          color: isActive ? Colors.blue : Colors.transparent,
        ),
      ],
    );
  }
}
