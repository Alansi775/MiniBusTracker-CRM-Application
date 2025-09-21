// lib/views/auth/sign_up_view.dart (التعديل النهائي لإضافة ElegantHoverButton)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../controllers/auth_controller.dart';
// 🚨 استيراد الزر الجديد
import '../../widgets/elegant_hover_button.dart'; 

class SignUpView extends GetView<AuthController> {
  const SignUpView({super.key});

  // الألوان الجديدة والمُعدَّلة للنمط الجديد
  static const Color primaryColor = Colors.black87; // أسود داكن (Brand Color)
  static const Color accentColor = Color(0xFFFFC107); // ذهبي/برتقالي (Action Color)
  static const Color backgroundColor = Color(0xFFF0F0F0); // خلفية أفتح
  static const Color secondaryTextColor = Colors.black54; 

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    // ... (لا يوجد تغيير في دالة _buildTextField) ...
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      style: const TextStyle(fontWeight: FontWeight.w500), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
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

  Widget _buildLogoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.directions_bus_filled_rounded,
          size: 32,
          color: accentColor,
        ),
        const SizedBox(width: 8),
        Text(
          'MINIBUS',
          style: GoogleFonts.playfairDisplay(
              fontSize: 28, 
              color: primaryColor, 
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
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 24),
                      onPressed: () => Get.back(),
                      tooltip: 'Geri Dön',
                    ),
                    _buildLogoHeader(),
                    const SizedBox(width: 40), 
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, thickness: 1.5, color: Colors.black12), 
                const SizedBox(height: 25),
                
                const Text(
                  'Yeni Hesap Oluştur',
                  style: TextStyle(fontSize: 18, color: secondaryTextColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _buildTextField(
                  controller: controller.nameController,
                  label: 'Adınız',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: controller.surnameController,
                  label: 'Soyadınız',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 15),

                Obx(() => _buildTextField(
                      controller: TextEditingController(text: controller.generatedUsername.value),
                      label: 'Kullanıcı Adınız',
                      icon: Icons.alternate_email,
                      readOnly: true,
                      suffixIcon: controller.generatedUsername.value.isNotEmpty
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    )),
                const SizedBox(height: 15),

                Obx(() => _buildTextField(
                      controller: controller.signupPasswordController,
                      label: 'Şifre',
                      icon: Icons.lock_outline,
                      obscureText: !controller.isPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor.withOpacity(0.7),
                        ),
                        onPressed: () => controller.isPasswordVisible.toggle(),
                      ),
                    )),
                const SizedBox(height: 15),

                Obx(() => _buildTextField(
                      controller: controller.signupConfirmPasswordController,
                      label: 'Şifre Tekrar',
                      icon: Icons.lock_open_outlined,
                      obscureText: !controller.isConfirmPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isConfirmPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                          color: primaryColor.withOpacity(0.7),
                        ),
                        onPressed: () => controller.isConfirmPasswordVisible.toggle(),
                      ),
                    )),
                const SizedBox(height: 40),

                // 🚨🚨 استبدال ElevatedButton بـ ElegantHoverButton
                Obx(() => controller.isLoading.value
                    ? CircularProgressIndicator(color: accentColor)
                    : ElegantHoverButton(
                        onPressed: controller.signUp,
                        text: 'Kayıt Ol',
                    )),
                
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    'Zaten hesabım var',
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