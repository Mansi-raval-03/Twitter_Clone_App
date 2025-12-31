import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/controller/notification_controller.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isloginLoading = false.obs;
  final isGoogleLoading = false.obs;
  final isPasswordVisible = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );
  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  // Validate form fields
  Future<void> login() async {
    try {
      isloginLoading.value = true;

      final email = emailController.text.trim();
      final password = passwordController.text;

      // Authenticate with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate on success
      if (userCredential.user != null) {
        // Ensure user document exists (in case it was deleted)
        await _ensureUserDocumentExists(userCredential.user!);
        
        Get.snackbar('Success', 'Login successful');
        // Ensure NotificationController is running and listening for this user
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          if (!Get.isRegistered<NotificationController>()) {
            final notif = NotificationController();
            Get.put<NotificationController>(notif);
            notif.startListener(uid);
          } else {
            try {
              Get.find<NotificationController>().startListener(uid);
            } catch (_) {}
          }
        }
        Get.offAllNamed(AppRoute.mainNavigation);
      }
      // Handle other cases if needed
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
      isloginLoading.value = false;
    }
  }

  // Google Sign-In
  Future<void> loginWithGoogle() async {
    try {
      isGoogleLoading.value = true;

      // Trigger Google sign-in flow using a single shared instance
      final googleUser = await _googleSignIn.signIn();

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
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Ensure user document exists in Firestore
      final user = userCredential.user;
      if (user != null) {
        await _ensureUserDocumentExists(user);
      }

      // Navigate on success
      Get.snackbar('Success', 'Google Sign-In successful');
      // Ensure NotificationController is running and listening for this user
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        if (!Get.isRegistered<NotificationController>()) {
          final notif = NotificationController();
          Get.put<NotificationController>(notif);
          notif.startListener(uid);
        } else {
          try {
            Get.find<NotificationController>().startListener(uid);
          } catch (_) {}
        }
      }
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
    } on PlatformException catch (e) {
      // Common Android error: ApiException: 10 -> developer configuration issue (SHA mismatch / OAuth client)
      if (e.code == 'sign_in_failed' && e.message != null && e.message!.contains('ApiException: 10')) {
        Get.snackbar(
          'Error',
          'Google Sign-In failed (ApiException: 10).\nPlease add your app SHA-1/ SHA-256 to the Firebase Console and Google Cloud OAuth client, download an updated google-services.json, then rebuild the app.',
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 8),
        );
      } else {
        Get.snackbar('Error', 'Google Sign-In failed: ${e.message ?? e.toString()}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Google Sign-In failed: ${e.toString()}');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Ensure user document exists in Firestore (for Google Sign-in or first-time users)
  Future<void> _ensureUserDocumentExists(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'username': user.displayName ?? user.email?.split('@')[0] ?? 'user',
          'handle': '@${user.email?.split('@')[0] ?? 'user'}',
          'bio': '',
          'location': '',
          'website': '',
          'profileImage': user.photoURL ?? '',
          'profilePicture': user.photoURL ?? '',
          'coverImage': '',
          'createdAt': FieldValue.serverTimestamp(),
          'followers': 0,
          'following': 0,
          'posts': 0,
          'likes': 0,
        });
      }
    } catch (e) {
      print('Error ensuring user document: $e');
    }
  }

  // Field validators
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
    // cleanup if needed
    
    super.onClose();
  }
}
