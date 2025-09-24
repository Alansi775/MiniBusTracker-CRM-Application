// lib/views/auth/sign_in_view.dart 

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_shimmer.dart'; 
//  استيراد زر التحويم
import '../../widgets/elegant_hover_button.dart'; 

class SignInView extends GetView<AuthController> {
  const SignInView({super.key});

  // الألوان الجديدة والمُعدَّلة
  static const Color primaryColor = Colors.black87; // أسود داكن (Brand Color)
  static const Color accentColor = Color(0xFFFFC107); // ذهبي/برتقالي (Action Color)
  static const Color backgroundColor = Color(0xFFF0F0F0); // خلفية أفتح

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onSubmitted: onSubmitted, 
      style: const TextStyle(fontWeight: FontWeight.w500), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)), 
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white, 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0), 
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: accentColor, width: 2), 
        ),
      ),
    );
  }

  Widget _buildElegantLogoContent() {
    return Column(
      children: [
        // الأيقونة الذهبية البارزة 
        Icon(
          Icons.directions_bus_filled_rounded,
          size: 48,
          color: accentColor,
        ),
        const SizedBox(height: 10),

        // النص بدون 'fontWeight' ليكون ناعماً
        Text(
          'MİNİBÜSCRM',
          style: GoogleFonts.playfairDisplay(
              fontSize: 36, 
              color: primaryColor, 
          ),
        ),
        
        // تاق أو خط فاصل للتأكيد
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            width: 80, 
            height: 3,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Container(
            width: 450, 
            padding: const EdgeInsets.all(50.0), 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.0), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), 
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                
                CustomShimmer(
                  child: _buildElegantLogoContent(),
                ),
                
                const SizedBox(height: 35), 

                Text(
                  'Sürücü Girişi',
                  style: TextStyle(
                    fontSize: 18, 
                    color: primaryColor.withOpacity(0.7), 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Input fields
                _buildTextField(
                  controller: controller.emailController,
                  label: 'E-posta Adresi',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                Obx(() => _buildTextField(
                      controller: controller.passwordController,
                      label: 'Şifre',
                      icon: Icons.lock_outline,
                      obscureText: !controller.isPasswordVisible.value,
                      onSubmitted: (_) => controller.signIn(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: primaryColor.withOpacity(0.7),
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    )),
                const SizedBox(height: 40),

                // زر تسجيل الدخول (تم استبداله بـ ElegantHoverButton)
                Obx(() => controller.isLoading.value
                    ? CircularProgressIndicator(color: accentColor)
                    : ElegantHoverButton(
                        onPressed: controller.signIn,
                        text: 'Giriş Yap',
                    )),
                
                const SizedBox(height: 20),

                // زر التوجيه لصفحة التسجيل
                TextButton(
                  onPressed: () {
                    Get.toNamed('/signup'); 
                  },
                  child: const Text(
                    'Hesabın yok mu? Kayıt Ol',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
