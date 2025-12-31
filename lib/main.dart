import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:twitter_clone_app/Repository/firebase_api.dart';
import 'package:twitter_clone_app/Repository/get_storage_repository.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';
import 'package:twitter_clone_app/firebase_options.dart';
import 'package:twitter_clone_app/route/app_module.dart';
import 'package:twitter_clone_app/theme/app_theme.dart';

final navigatoreKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  await GetStorage.init();

  // Register GetStorageRepository for dependency injection
  Get.put<GetStorageRepository>(GetStorageRepository(GetStorage()));
  
  // Always bind NotificationController to auth state so message notifications land
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      final notif = Get.put<NotificationController>(NotificationController(), permanent: true);
      notif.startListener(user.uid);
    }
  });
  
  // Determine initial route based on authentication state
  // Note: Firebase Auth automatically persists user sessions on mobile platforms
  final initialRoute = FirebaseAuth.instance.currentUser != null ? AppRoute.mainNavigation : AppRoute.login;
  
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
      navigatorKey: navigatoreKey,
      enableLog: true,
      initialRoute: initialRoute,
      getPages: AppPage.routes,
    );
  }
}

