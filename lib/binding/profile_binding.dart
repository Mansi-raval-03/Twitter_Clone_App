import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/profile_controller.dart';
import 'package:twitter_clone_app/controller/tab_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    /// Create a fresh controller per usage; avoid permanent singleton so Form GlobalKey is not reused simultaneously
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<ProfileTabController>(() => ProfileTabController());
  }
}
