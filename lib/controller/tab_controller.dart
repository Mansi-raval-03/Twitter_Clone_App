import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileTabController extends GetxController with GetSingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 4, vsync: this);
  }
 // Tweets
  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}