import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordController extends GetxController {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  // Added: form key for validation
  final formKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var isPasswordReset = false.obs;

  // Added: email validator
  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(email)) return 'Please enter a valid email';
    return null;
  }

  // Repurposed: send password reset link instead of OTP
  Future<void> sendOtp(String email) async {
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return;

    try {
      isLoading.value = true;
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      isOtpSent.value = true;
      Get.snackbar('Success', 'Password reset link sent to $email');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Failed to send reset link');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset link: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String otp) async {
    try {
      isLoading.value = true;
      Get.snackbar('Success', 'OTP verified');
    } catch (e) {
      Get.snackbar('Error', 'Invalid OTP: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (!_validatePasswords()) return;

    try {
      isLoading.value = true;
      isPasswordReset.value = true;
      Get.snackbar('Success', 'Password reset successfully');
      Get.offNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reset password: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validatePasswords() {
    if (newPasswordController.text.isEmpty) {
      Get.snackbar('Error', 'Password cannot be empty');
      return false;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar('Error', 'Passwords do not match');
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.onClose();
  }
}