import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/home_conteoller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }

}