import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Twitter',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...[
              ('Home', Icons.home),
              ('Explore', Icons.explore),
              ('Messages', Icons.mail),
              ('Bookmarks', Icons.bookmark),
              ('Profile', Icons.person),
            ]
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(item.$2, size: 24),
                    const SizedBox(width: 16),
                    Text(item.$1, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            )
            ,
      ],
    );
  }
}