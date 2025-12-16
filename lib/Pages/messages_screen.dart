import 'package:flutter/material.dart';


class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Column(
        children: [
           Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg'),
                  ),
                  title: Text('User 1'),
                  subtitle: Text('Message content here...'),
                  trailing: Text('Time'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search messages',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
