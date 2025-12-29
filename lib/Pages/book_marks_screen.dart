import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
      ),
      body: Center(
        child: Text(
          'Your Bookmarks will appear here',
          style: TextStyle(fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bookmarks_fab',
        onPressed: () {
          // Add your bookmark action here
        },
        tooltip: 'Add Bookmark',
        child: Icon(Icons.add, color: Theme.of(context).primaryIconTheme.color,),
      ),
    );
  }
}