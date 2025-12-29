import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:twitter_clone_app/Repository/get_storage_repository.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';
import 'package:twitter_clone_app/route/app_module.dart';
import 'package:twitter_clone_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();

  // Register GetStorageRepository for dependency injection
  Get.put<GetStorageRepository>(GetStorageRepository(GetStorage()));

  final user = FirebaseAuth.instance.currentUser;
  // If a user is already signed in, register NotificationController
  // and start the Firestore listener so notifications arrive live.
  if (user != null) {
    final notif = NotificationController();
    Get.put<NotificationController>(notif);
    notif.startFirestoreListener(user.uid);
  }
  
  // Determine initial route based on authentication state
  // Note: Firebase Auth automatically persists user sessions on mobile platforms
  final initialRoute = user != null ? AppRoute.mainNavigation : AppRoute.login;
  
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppThemes.lightMode,
      darkTheme: AppThemes.darkMode,
      themeMode: ThemeMode.system,
      title: 'Twitter Clone',
      debugShowCheckedModeBanner: false,

      enableLog: true,
      initialRoute: initialRoute,
      getPages: AppPage.routes,
    );
  }
}
