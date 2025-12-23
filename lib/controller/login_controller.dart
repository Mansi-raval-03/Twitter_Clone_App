import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:twitter_clone_app/Route/route.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  Future<void> login() async {
    try {
      isLoading.value = true;

      final email = emailController.text.trim();
      final password = passwordController.text;

      // Authenticate with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        Get.snackbar('Success', 'Login successful');
        Get.offAllNamed(AppRoute.mainNavigation);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'User not found. Please sign up first.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Invalid email or password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'User account is disabled';
      }
      Get.snackbar('Error', errorMessage);
    } catch (e) {
      Get.snackbar('Error', 'Login failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      // Trigger Google sign-in flow
      final googleUser = await GoogleSignIn().signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        return;
      }

      // Obtain auth details
      final googleAuth = await googleUser.authentication;

      // Guard: both tokens missing leads to plugin/internal null assertions
      final hasIdToken = googleAuth.idToken != null && googleAuth.idToken!.isNotEmpty;
      final hasAccessToken = googleAuth.accessToken != null && googleAuth.accessToken!.isNotEmpty;
      if (!hasIdToken && !hasAccessToken) {
        Get.snackbar('Error', 'Google Sign-In failed: missing auth tokens');
        return;
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: hasIdToken ? googleAuth.idToken : null,
        accessToken: hasAccessToken ? googleAuth.accessToken : null,
      );

      // Sign in with Firebase using the Google credential
      await _auth.signInWithCredential(credential);

      // Navigate on success
      Get.snackbar('Success', 'Google Sign-In successful');
      Get.offAllNamed(AppRoute.mainNavigation);

        
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Google Sign-In failed';
      if (e.code == 'account-exists-with-different-credential') {
        errorMessage = 'An account already exists with the same email address but different sign-in credentials.';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid credentials. Please try again.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Google Sign-In is not enabled. Please contact support.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      }
      Get.snackbar('Error', errorMessage);
    } catch (e) {
      Get.snackbar('Error', 'Google Sign-In failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}