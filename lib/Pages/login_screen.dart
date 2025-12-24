import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twitter_clone_app/Route/route.dart';
import 'package:twitter_clone_app/controller/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
   LoginScreen({super.key});

   @override
     final LoginController controller = Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
        
             
        
                  /// Sign in heading
                  Center(
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F1419),
                      ),
                    ),
                  ),
        
                  const SizedBox(height: 36),
        
                  /// Google sign-in button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: Obx(
                      () => OutlinedButton(
                        onPressed: controller.isLoading.value ? null : () => controller.loginWithGoogle(),
                        style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFCFD9DE),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F1419),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(width: 8),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F1419),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
        
                  const SizedBox(height: 16),
        
                  /// Divider
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFCFD9DE))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Color(0xFF536471),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFCFD9DE))),
                    ],
                  ),
        
                  const SizedBox(height: 16),
        
                  /// Email Field
                  TextFormField(
                    controller: controller.emailController,
                    validator: (value) => controller.validateEmail(value),
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF0F1419),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Phone, email, or username',
                      hintStyle: const TextStyle(
                        color: Color(0xFF536471),
                        fontSize: 17,
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
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFF536471),
                          fontSize: 17,
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
        
                  /// Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (controller.formKey.currentState?.validate() ?? false) {
                                  controller.login();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1419),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
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
                                'Log in',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
        
                  const SizedBox(height: 16),
        
                  /// Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                      Get.toNamed(AppRoute.forgotPasswordScreen);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1DA1F2),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
        
                  const SizedBox(height: 20),
        
                  /// Sign Up Link
                  Align(alignment: Alignment.centerRight, child: _buildSignUpLink()),
        
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return  Row(
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF536471),
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.toNamed(AppRoute.signup);
              },
              child: const Text(
                'Sign up',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1DA1F2),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        );
  }
}
