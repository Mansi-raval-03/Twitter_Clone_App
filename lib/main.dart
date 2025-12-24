import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/login_screen.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Pages/search_screen.dart';
import 'package:twitter_clone_app/Pages/signup_screen.dart';
import 'package:twitter_clone_app/Pages/forgot_password_screen.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';
import 'package:twitter_clone_app/binding/home_binding.dart';
import 'package:twitter_clone_app/binding/login_binding.dart';
import 'package:twitter_clone_app/binding/notification_binding.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';
import 'package:twitter_clone_app/binding/profile_binding.dart';
import 'package:twitter_clone_app/binding/reset_binding.dart';
import 'package:twitter_clone_app/binding/search_binding.dart';
import 'package:twitter_clone_app/binding/signup_binding.dart';
import 'package:twitter_clone_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final user = FirebaseAuth.instance.currentUser;
  // If a user is already signed in, register NotificationController
  // and start the Firestore listener so notifications arrive live.
  if (user != null) {
    final notif = NotificationController();
    Get.put<NotificationController>(notif);
    notif.startFirestoreListener(user.uid);
  }
  runApp(MyApp(initialRoute: user != null ? AppRoute.mainNavigation : AppRoute.login));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, this.initialRoute = AppRoute.login});

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
      getPages: [
        GetPage(name: AppRoute.login, page: () =>  LoginScreen(),
            binding: LoginBinding()),
        GetPage(name: AppRoute.signup, page: () => const SignupScreen(),
            binding: SignupBinding()),
        GetPage(name: AppRoute.forgotPasswordScreen, page: () => ForgotPasswordScreen(),
            binding: ResetBinding()),
        GetPage(name: AppRoute.home, page: () => HomeScreen( ),
            binding: HomeBinding()),
        GetPage(name: AppRoute.profileScreen, page: () => ProfileScreen(viewedUserId: '',),
            binding: ProfileBinding()),
        GetPage(name: AppRoute.searchScreen, page: () => SearchScreen(),
            binding: SearchBinding()),
        GetPage(name: AppRoute.notificationsScreen, page: () => NotificationScreen(),
            binding: NotificationBinding()),
        GetPage(
          name: AppRoute.mainNavigation,
          page: () => MainNavigationScreen(user: null, tweets: [], replies: []),
        ),

      ],
    );
  }
}
