// lib/views/admin/add_user_view.dart (التعديل للتصميم الحديث والتوسط)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../data/models/user_model.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb; // لاختبار الويب

class AddUserView extends GetView<AdminController> {
  const AddUserView({super.key});

  static const Color primaryColor = Color(0xFF0D47A1);

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false, // لتحديد حقل كلمة المرور
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  // دالة مساعدة لتحويل الـ Enum إلى نص عرض أنيق
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'YÖNETİCİ (Admin)';
      case UserRole.user:
        return 'KULLANICI (User)';
      default:
        return role.toString().split('.').last.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ النقطة الثانية: جعل الشاشة في المنتصف
    double cardWidth = kIsWeb ? 550 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Kullanıcı Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center( // <== استخدام Center للتوسط
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // حقل عرض كلمة المرور المولدة (لنسخها يدوياً)
                Obx(() => _buildTextField(
                  controller: TextEditingController(text: controller.generatedPassword.value),
                  label: 'Geçici Şifre',
                  icon: Icons.vpn_key_outlined,
                  readOnly: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, color: primaryColor),
                    tooltip: 'Şifreyi Kopyala',
                    onPressed: controller.copyPasswordToClipboard, // دالة النسخ
                  ),
                )),
                const SizedBox(height: 15),

                // حقول المستخدم
                _buildTextField(
                  controller: controller.nameController,
                  label: 'Adı',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: controller.surnameController,
                  label: 'Soyadı',
                  icon: Icons.badge,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: controller.emailController,
                  label: 'E-posta Adresi',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 25),

                // ⚠️ النقطة الثالثة: استبدال Dropdown بتصميم Tags/Chips
                const Text('Kullanıcı Rolü Seçin:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                Obx(() => Wrap(
                      spacing: 10.0,
                      children: controller.availableRoles.map((UserRole role) {
                        final isSelected = controller.selectedRole.value == role;
                        return ChoiceChip(
                          label: Text(_getRoleDisplayName(role)),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.grey.shade200,
                          side: BorderSide(
                            color: isSelected ? primaryColor : Colors.grey.shade400,
                            width: 1,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              controller.selectedRole.value = role;
                            }
                          },
                        );
                      }).toList(),
                    )),
                
                const SizedBox(height: 40),

                // Add User Button
                Obx(() => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : ElevatedButton(
                        onPressed: controller.createUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Kullanıcı Oluştur',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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