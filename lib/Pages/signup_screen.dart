import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/controller/signup_controller.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {  context=StatelessElement(SignupScreen());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Color(0xFF0F1419),
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Sign up',
          style: TextStyle(
            color: Color(0xFF0F1419),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Create account heading
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1419),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Name Field
                  TextFormField(
                    controller: controller.nameController,
                    validator: (value) => controller.validateName(value),
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF0F1419),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: const TextStyle(
                        color: Color(0xFF536471),
                        fontSize: 17,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFF1DA1F2),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFCFD9DE),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFCFD9DE),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFF1DA1F2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Email Field
                  TextFormField(
                    controller: controller.emailController,
                    validator: (value) => controller.validateEmail(value),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF0F1419),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(
                        color: Color(0xFF536471),
                        fontSize: 17,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFF1DA1F2),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFCFD9DE),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFFCFD9DE),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: Color(0xFF1DA1F2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Password Field
                  Obx(
                    () => TextFormField(
                      controller: controller.passwordController,
                      validator: (value) => controller.validatePassword(value),
                      obscureText: !controller.isPasswordVisible.value,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF0F1419),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFF536471),
                          fontSize: 17,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF1DA1F2),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFCFD9DE),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFCFD9DE),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFF1DA1F2),
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF536471),
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Confirm Password Field
                  Obx(
                    () => TextFormField(
                      controller: controller.confirmPasswordController,
                      validator: (value) => controller.validateConfirmPassword(value),
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF0F1419),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFF536471),
                          fontSize: 17,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: Color(0xFF1DA1F2),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFCFD9DE),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFCFD9DE),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFF1DA1F2),
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isConfirmPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF536471),
                          ),
                          onPressed: controller.toggleConfirmPasswordVisibility,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  /// Terms of Service Notice
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF536471),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'By signing up, you agree to the ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: Color(0xFF1DA1F2),
                          ),
                        ),
                        TextSpan(
                          text: ' and ',
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFF1DA1F2),
                          ),
                        ),
                        TextSpan(
                          text: ', including ',
                        ),
                        TextSpan(
                          text: 'Cookie Use',
                          style: TextStyle(
                            color: Color(0xFF1DA1F2),
                          ),
                        ),
                        TextSpan(
                          text: '.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(
                      () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DA1F2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (controller.formKey.currentState?.validate() ?? false) {
                                  controller.signup();
                                }
                              },
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF536471),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoute.login);
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1DA1F2),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
