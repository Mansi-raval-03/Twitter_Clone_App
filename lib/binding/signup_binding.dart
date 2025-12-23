import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
   
    Get.put(SignupController(), permanent: true);
  }
}