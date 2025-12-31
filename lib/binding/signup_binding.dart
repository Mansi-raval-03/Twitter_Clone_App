import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    // Create a fresh controller per usage; avoid permanent singleton so Form GlobalKey is not reused simultaneously
    Get.put<SignupController>(SignupController());
  }
}
