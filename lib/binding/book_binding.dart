import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/bookmark_controller.dart';

class BookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookmarkController>(() => BookmarkController());
  }
}
