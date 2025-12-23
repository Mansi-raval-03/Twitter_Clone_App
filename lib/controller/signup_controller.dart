import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twitter_clone_app/Route/route.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.toggle();
  }

  Future<void> signup() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;

      // Check if user already exists
      final userExists = await _checkUserExists(email);
      if (userExists) {
        Get.snackbar('Error', 'Email already registered. Please login instead.');
        return;
      }

      // Create user account with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        Get.snackbar('Error', 'Failed to create account');
        return;
      }

      // Update user display name
      await user.updateDisplayName(name);

      // Save user data to Firestore
      await _saveUserToFirestore(user.uid, name, email);

      // Sign out the user after registration
      await _auth.signOut();

      Get.snackbar(
        'Success', 
        'Account created successfully! Please login to continue.',
        duration: const Duration(seconds: 3),
      );
      Get.offAllNamed(AppRoute.login);

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed';
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email is already registered';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      }
      Get.snackbar('Error', errorMessage);
    } catch (e) {
      Get.snackbar('Error', 'Signup failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateForm() {
    final nameError = validateName(nameController.text);
    final emailError = validateEmail(emailController.text);
    final passwordError = validatePassword(passwordController.text);
    final confirmPasswordError = validateConfirmPassword(confirmPasswordController.text);

    if (nameError != null) {
      Get.snackbar('Error', nameError);
      return false;
    }
    if (emailError != null) {
      Get.snackbar('Error', emailError);
      return false;
    }
    if (passwordError != null) {
      Get.snackbar('Error', passwordError);
      return false;
    }
    if (confirmPasswordError != null) {
      Get.snackbar('Error', confirmPasswordError);
      return false;
    }
    return true;
  }

  Future<bool> _checkUserExists(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveUserToFirestore(String uid, String name, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'username': email.split('@')[0],
      'bio': '',
      'location': '',
      'website': '',
      'profileImage': '',
      'coverImage': '',
      'createdAt': FieldValue.serverTimestamp(),
      // store numeric counts so FieldValue.increment works reliably
      'followers': 0,
      'following': 0,
      'posts': 0,
      'likes': 0,
    });
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
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
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}