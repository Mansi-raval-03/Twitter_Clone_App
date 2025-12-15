import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Twitter',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildTrendingSection('Technology', '#Flutter', '125K'),
          _buildTrendingSection('Programming', '#Dart', '89K'),
          _buildTrendingSection('Mobile', '#MobileApp', '234K'),
          _buildTrendingSection('Trending', '#TwitterClone', '567K'),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(String category, String trend, String count) {
    return ListTile(
      title: Text(category, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(trend, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: Text('$count posts'),
      onTap: () {},
    );
  }
}