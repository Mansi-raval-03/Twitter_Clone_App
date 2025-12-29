import 'package:twitter_clone_app/controller/search_controller.dart';
import 'package:get/get.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    /// Create a fresh controller per usage; avoid permanent singleton so Form GlobalKey is not reused simultaneously
    Get.lazyPut<SearchController>(() => SearchController());
  }
}