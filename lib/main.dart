import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/login_screen.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Pages/search_screen.dart';
import 'package:twitter_clone_app/Pages/signup_screen.dart';
import 'package:twitter_clone_app/Pages/forgot_password_screen.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';
import 'package:twitter_clone_app/binding/home_binding.dart';
import 'package:twitter_clone_app/binding/login_binding.dart';
import 'package:twitter_clone_app/binding/profile_binding.dart';
import 'package:twitter_clone_app/binding/reset_binding.dart';
import 'package:twitter_clone_app/binding/search_binding.dart';
import 'package:twitter_clone_app/binding/signup_binding.dart';
import 'package:twitter_clone_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppThemes().lightMode,
      darkTheme: AppThemes().darkMode,
      themeMode: ThemeMode.system,
      title: 'Twitter Clone',
      debugShowCheckedModeBanner: false,
      
      enableLog: true,
      initialRoute: AppRoute.login,
      getPages: [
        GetPage(name: AppRoute.login, page: () => const LoginScreen(),
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
        GetPage(
          name: AppRoute.mainNavigation,
          page: () => MainNavigationScreen(user: null, tweets: [], replies: []),
        ),

      ],
    );
  }
}
