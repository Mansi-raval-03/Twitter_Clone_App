import 'package:get/get.dart';
import 'package:twitter_clone_app/Pages/forgot_password_screen.dart';
import 'package:twitter_clone_app/Pages/home_screen.dart';
import 'package:twitter_clone_app/Pages/login_screen.dart';
import 'package:twitter_clone_app/Pages/notification_screen.dart';
import 'package:twitter_clone_app/Pages/profile_screen.dart';
import 'package:twitter_clone_app/Pages/search_screen.dart';
import 'package:twitter_clone_app/Pages/signup_screen.dart';
import 'package:twitter_clone_app/Widgets/main_navigation.dart';
import 'package:twitter_clone_app/binding/notification_binding.dart';
import 'package:twitter_clone_app/binding/profile_binding.dart';
import 'package:twitter_clone_app/binding/reset_binding.dart';
import 'package:twitter_clone_app/binding/search_binding.dart';
import 'package:twitter_clone_app/binding/signup_binding.dart';
import '../binding/home_binding.dart';
import '../binding/login_binding.dart';
import 'route.dart';

class AppPage {
  AppPage._();

  static final routes = [
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

  ];
}
