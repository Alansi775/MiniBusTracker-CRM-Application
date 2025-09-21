// lib/views/admin/pending_requests_view.dart (التصميم الموحد: الأسود/الذهبي)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // 💡 استيراد الخطوط
import '../../controllers/admin_controller.dart';
import '../../data/models/user_model.dart';
import '../../widgets/custom_shimmer.dart'; // يمكن استخدامه لاحقاً

class PendingRequestsView extends GetView<AdminController> {
  const PendingRequestsView({super.key});

  // 🚨 الألوان الجديدة الموحدة
  static const Color primaryColor = Colors.black87; // أسود داكن (الرئيسي)
  static const Color accentColor = Color(0xFFFFC107); // لون مكمل (ذهبي/برتقالي)
  static const Color successColor = Color(0xFF28A745); // أخضر هادئ (للموافقة)
  static const Color rejectColor = Color(0xFFDC3545); // أحمر نبيذي (للرفض)
  static const Color lightBackground = Color(0xFFF0F0F0); // خلفية فاتحة

  // 🚨 تعريف الخطوط كـ static final
  static final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
  static final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: lightBackground, // 🚨 تطبيق الخلفية الفاتحة
      body: SafeArea(
        child: Column(
          children: [
            // 🚨 استخدام Header المخصص بدلاً من AppBar
            _buildCustomHeader(), 
            
            Expanded(
              child: Obx(() {
                if (controller.isFetchingRequests.value) {
                  return Center(child: CircularProgressIndicator(color: accentColor)); // 🚨 لون الذهبي
                }

                if (controller.pendingUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 60, color: successColor), // 🚨 لون النجاح
                        const SizedBox(height: 10),
                        Text('Bekleyen istek bulunmamaktadır.', style: secondaryTextStyle.copyWith(fontSize: 18, color: Colors.black54)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20.0), // زيادة البادينج قليلاً
                  itemCount: controller.pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = controller.pendingUsers[index];
                    return _buildRequestCard(user);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // --- CUSTOM HEADER (AppBar البديل) ---
  // ----------------------------------------------------
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 25, bottom: 15, left: 20, right: 20),
      decoration: BoxDecoration(
        color: primaryColor, // 🚨 اللون الأساسي: الأسود الداكن
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الرجوع
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
            tooltip: 'Geri Dön',
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 15),
          // العنوان
          Icon(Icons.pending_actions_rounded, color: accentColor, size: 30), // 🚨 الأيقونة بالذهبي
          const SizedBox(width: 10),
          Text(
            'BEKLEYEN İSTEKLER', 
            style: primaryTextStyle.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // --- REQUEST CARD ---
  // ----------------------------------------------------
  Widget _buildRequestCard(UserModel user) {
    // القيمة الافتراضية للتخصيص
    final Rx<UserRole> selectedRole = (user.role == UserRole.pending) ? UserRole.user.obs : user.role.obs; 

    return Card(
      margin: const EdgeInsets.only(bottom: 15), // زيادة الهامش السفلي
      elevation: 5, // زيادة الظل قليلاً
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // حواف أكثر دائرية
      child: Padding(
        padding: const EdgeInsets.all(20.0), // زيادة البادينج
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚨 تطبيق الخط الجديد
            Text(
              '${user.name} ${user.surname}', 
              style: primaryTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: primaryColor)
            ),
            const Divider(height: 25, thickness: 1.5, color: Colors.black12), // فاصل أنيق
            
            _buildInfoRow(Icons.mail_outline, 'E-posta', user.email ?? 'Yok'),
            _buildInfoRow(Icons.account_circle_outlined, 'Kullanıcı Adı', user.username ?? 'Yok'),
            
            const SizedBox(height: 20),
            // 🚨 تطبيق الخط الجديد
            Text(
              'Atanacak Rol:', 
              style: secondaryTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            
            // اختيار الدور
            Obx(() => Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: controller.approvalRoles.map((role) {
                    final isSelected = selectedRole.value == role;
                    return ChoiceChip(
                      label: Text(role.toString().split('.').last.toUpperCase()),
                      selected: isSelected,
                      // 🚨 استخدام اللون الذهبي كلون اختيار
                      selectedColor: accentColor, 
                      // 🚨 تطبيق الخط الجديد
                      labelStyle: secondaryTextStyle.copyWith(
                          color: isSelected ? primaryColor : Colors.black54, 
                          fontWeight: FontWeight.bold
                      ),
                      // 🚨 تغيير شكل الشريحة عند الاختيار
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(color: isSelected ? accentColor : Colors.grey.shade300, width: 1.5),
                      onSelected: (bool selected) {
                        if (selected) selectedRole.value = role;
                      },
                    );
                  }).toList(),
                )),

            const SizedBox(height: 30),
            // أزرار الإجراءات
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 🚨 زر الرفض
                TextButton(
                  onPressed: () => controller.rejectRequest(user),
                  child: Text('Reddet', style: secondaryTextStyle.copyWith(color: rejectColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 15),
                // 🚨 زر الموافقة
                ElevatedButton.icon(
                  onPressed: () => controller.approveRequest(user, selectedRole.value),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text('Onayla', style: secondaryTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor, // 🚨 لون النجاح الأخضر
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentColor.withOpacity(0.8)), // 🚨 الأيقونات بالذهبي الخفيف
          const SizedBox(width: 10),
          Text('$title: ', style: secondaryTextStyle.copyWith(fontWeight: FontWeight.w600, color: primaryColor.withOpacity(0.8))),
          Expanded(child: Text(value, style: secondaryTextStyle.copyWith(color: Colors.black54))),
        ],
      ),
    );
  }
}