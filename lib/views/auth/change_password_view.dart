// lib/views/auth/change_password_view.dart 

import 'package:flutter/material.dart';
import 'package:get/get.dart';
//  استيراد Google Fonts
import 'package:google_fonts/google_fonts.dart'; 
import '../../controllers/auth_controller.dart';

class ChangePasswordView extends GetView<AuthController> {
  const ChangePasswordView({super.key});

  // الألوان الأنيقة الموحدة
  static const Color primaryColor = Colors.black87; // أسود داكن (Brand Color)
  static const Color accentColor = Color(0xFFFFC107); // ذهبي/برتقالي (Action Color)
  static const Color lightBackgroundColor = Color(0xFFF0F0F0); // خلفية فاتحة ونظيفة
  static const Color lightCardColor = Colors.white; // لون البطاقة
  
  // اللون الأساسي للزر
  static const Color buttonFillColor = primaryColor; 

  //  تعريف أنماط الخطوط
  static final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
  static final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);

  // ----------------------------------------------------
  // --- ويدجت حقل النص الأنيق (لا تغيير كبير) ---
  // ----------------------------------------------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      //  استخدام secondaryTextStyle للنصوص الداخلية
      style: secondaryTextStyle.copyWith(fontWeight: FontWeight.w500), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: secondaryTextStyle.copyWith(color: primaryColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: lightBackgroundColor, 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: accentColor, width: 2.5), 
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // --- البناء الرئيسي (BUILD) ---
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar( 
        //  تطبيق الخط على عنوان الـ AppBar
        title: Text(
          'Şifre Güncelleme', 
          style: primaryTextStyle.copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: lightCardColor, 
        elevation: 1, 
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: lightCardColor,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(35.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                
                // العنوان
                Text(
                  'Hesap Güvenliği', 
                  textAlign: TextAlign.center,
                  //  تطبيق الخط الجديد هنا
                  style: primaryTextStyle.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),
                
                // التاق الأنيق
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Parolanızı Yenileyin',
                    //  تطبيق الخط الجديد على التاق
                    style: secondaryTextStyle.copyWith(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 35),

                // New Password Field
                Obx(() => _buildTextField(
                      controller: controller.newPasswordController,
                      label: 'Yeni Şifre',
                      icon: Icons.vpn_key_rounded,
                      obscureText: !controller.isNewPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isNewPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor.withOpacity(0.7),
                        ),
                        onPressed: controller.toggleNewPasswordVisibility,
                      ),
                    )),
                const SizedBox(height: 20),

                // Confirm Password Field
                Obx(() => _buildTextField(
                      controller: controller.confirmPasswordController,
                      label: 'Yeni Şifre (Tekrar)',
                      icon: Icons.check_circle_outline,
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor.withOpacity(0.7),
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                    )),
                const SizedBox(height: 45),

                // Change Password Button
                Obx(() => controller.isLoading.value
                    ? CircularProgressIndicator(color: accentColor)
                    : ElevatedButton(
                        onPressed: controller.updatePassword, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonFillColor, 
                          foregroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          side: const BorderSide(color: accentColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 5,
                        ),
                        child: Text(
                          'Şifreyi Kaydet', 
                          //  تطبيق الخط الجديد على الزر
                          style: secondaryTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
