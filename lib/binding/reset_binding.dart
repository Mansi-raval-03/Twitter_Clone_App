import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/reset_pswd_controller.dart';

class ResetBinding extends Bindings {
  @override
  void dependencies() {
    /// Create a fresh controller per usage; avoid permanent singleton so Form GlobalKey is not reused simultaneously
    Get.lazyPut<ResetPasswordController>(() => ResetPasswordController());
  }

}