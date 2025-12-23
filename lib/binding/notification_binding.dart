import 'package:get/get.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationController>(() => NotificationController());
  } 
  
 }