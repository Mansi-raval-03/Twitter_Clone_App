import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/home_conteoller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    /// Create a fresh controller per usage; avoid permanent singleton so Form GlobalKey is not reused simultaneously
    Get.lazyPut<HomeController>(() => HomeController()); 
  }

}
