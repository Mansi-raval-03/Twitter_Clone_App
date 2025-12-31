import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/bookmark_controller.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  BookmarkController get _controller => Get.put(BookmarkController());

  @override
  Widget build(BuildContext context) {
    if (!_controller.isLoggedIn) {
      return _controller.buildNotLoggedInView(context);
    }

    return Scaffold(
      appBar: _controller.buildAppBar(context),
      body: _controller.buildBookmarksList(context),
    );
  }
}
