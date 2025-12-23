import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
   
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
  }
}