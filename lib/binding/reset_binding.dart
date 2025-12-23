import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/reset_pswd_controller.dart';

class ResetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResetPasswordController>(() => ResetPasswordController());
  }

}