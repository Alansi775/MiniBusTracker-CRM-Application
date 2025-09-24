// lib/views/admin/admin_dashboard_view.dart (التصميم الجديد والمعدل: الأسود/الذهبي)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // 💡 استيراد الخطوط
import '../../controllers/admin_controller.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../controllers/auth_controller.dart'; 
import '../../widgets/custom_shimmer.dart'; 

class AdminDashboardView extends GetView<AdminController> {
  const AdminDashboardView({super.key});


  static const Color primaryColor = Colors.black87; // أسود داكن (الرئيسي)
  static const Color activeColor = Color(0xFF28A745); // أخضر هادئ (Success Color)
  static const Color blockedColor = Color(0xFFDC3545); // أحمر نبيذي
  static const Color accentColor = Color(0xFFFFC107); // لون مكمل (ذهبي/برتقالي)
  static const Color lightBackground = Color(0xFFF0F0F0); // خلفية فاتحة

  // تعريف الخطوط كـ static final
  static final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
  static final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);
  
  @override
  Widget build(BuildContext context) {
    
    final currentUserRole = Get.find<AuthService>().currentUser.value?.role;
    final bool isSuperAdmin = currentUserRole == UserRole.superAdmin;
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      // تطبيق الخلفية الفاتحة الجديدة
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(isSuperAdmin, authController),
            
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return CustomShimmer(child: _buildLoadingDashboard());
                }
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      
                      const SizedBox(height: 30),
                      // تطبيق الخط الجديد
                      Text(
                        'Sistem Kullanıcı Yönetimi', 
                        style: primaryTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
                      const Divider(height: 20, thickness: 2, color: primaryColor), // تطبيق لون الفاصل
                      
                      _buildUserTabs(isSuperAdmin),
                    ],
                  ),
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
  Widget _buildCustomHeader(bool isSuperAdmin, AuthController authController) {
  // جلب معلومات المستخدم الحالي
  final currentUser = authController.authService.currentUser.value;
  final userName = currentUser?.name ?? 'Admin';
  final userRole = currentUser?.role.toString().split('.').last.toUpperCase() ?? 'ADMIN';
  final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';
  
  return Container(
    padding: const EdgeInsets.only(top: 25, bottom: 15, left: 20, right: 20),
    decoration: BoxDecoration(
      color: primaryColor, // اللون الأساسي: الأسود الداكن
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: accentColor, size: 30), // الأيقونة بالذهبي
            const SizedBox(width: 10),
            // تطبيق الخط الجديد
            Text(
              'YÖNETİCİ PANELİ', 
              style: primaryTextStyle.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        
        // 🚨 التعديل الثاني: استبدال الأيقونات المنفصلة بالـ PopupMenuButton (Avatar Menu)
        Row(
          children: [
            if (isSuperAdmin)
              IconButton(
                icon: Icon(Icons.pending_actions_rounded, color: accentColor, size: 28), // الأيقونة بالذهبي
                tooltip: 'Bekleyen İstekler',
                onPressed: () => Get.toNamed('/pending_requests'),
              ),
            
            // إضافة قائمة المستخدم المنبثقة (Avatar Menu)
            PopupMenuButton<String>(
              color: Colors.white, // خلفية القائمة بيضاء
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 30),
              
              onSelected: (String result) {
                if (result == 'logout') {
                  authController.signOut();
                } else if (result == 'change_password') {
                  Get.toNamed('/change_password');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                
                // 1. رأس القائمة (معلومات المستخدم)
                PopupMenuItem<String>(
                  enabled: false, // لا يمكن الضغط عليه
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // الافتار (Avatar)
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: accentColor, // خلفية ذهبية
                            child: Text(
                              initial, 
                              style: secondaryTextStyle.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // اسم المستخدم
                              Text(
                                userName, 
                                style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              // دور المستخدم
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  userRole, 
                                  style: secondaryTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor.withOpacity(0.7)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                    ],
                  ),
                ),

                // 2. خيار تغيير كلمة المرور
                PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: primaryColor.withOpacity(0.8)),
                      const SizedBox(width: 10),
                      Text('Şifre Değiştir', style: secondaryTextStyle),
                    ],
                  ),
                ),
                
                // 3. خيار تسجيل الخروج
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: blockedColor), // لون أحمر للـ Logout
                      const SizedBox(width: 10),
                      Text('Çıkış Yap', style: secondaryTextStyle.copyWith(color: blockedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


  // ----------------------------------------------------
  // --- STATS ROW (عداد المستخدمين) ---
  // ----------------------------------------------------

  Widget _buildStatsRow() {
    return Obx(() {
      final adminsCount = controller.allUsers.where((u) => u.role == UserRole.admin).length;
      final usersCount = controller.allUsers.where((u) => u.role == UserRole.user).length;
      final pendingCount = controller.pendingUsers.length;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            title: 'Toplam Yönetici', 
            count: adminsCount, 
            icon: Icons.shield_sharp, 
            color: primaryColor // اللون الأسود
          ),
          _buildStatCard(
            title: 'Toplam Sürücü', 
            count: usersCount, 
            icon: Icons.people_alt, 
            color: activeColor // اللون الأخضر
          ),
          _buildStatCard(
            title: 'Bekleyen İstekler', 
            count: pendingCount, 
            icon: Icons.pending_actions, 
            color: accentColor // اللون الذهبي
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({required String title, required int count, required IconData icon, required Color color}) {
    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 5),
              Text(
                title,
                style: secondaryTextStyle.copyWith(fontSize: 14, color: Colors.grey), // تطبيق الخط
              ),
              const SizedBox(height: 5),
              // تطبيق الخط الجديد للعدد
              Text(
                count.toString(),
                style: primaryTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // --- BUILDER METHODS ---
  // ----------------------------------------------------

  Widget _buildUserTabs(bool isSuperAdmin) {
    return Container(
      height: Get.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DefaultTabController(
        length: 2, 
        child: Column(
          children: [
            TabBar(
              labelColor: primaryColor, // لون التبويب النشط: الأسود
              indicatorColor: accentColor, // لون المؤشر: الذهبي
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 4.0,
              tabs: [
                // تطبيق الخط الجديد
                Tab(child: Text('Yöneticiler (${controller.allUsers.where((u) => u.role == UserRole.admin).length})', style: secondaryTextStyle)),
                Tab(child: Text('Müşteri (${controller.allUsers.where((u) => u.role == UserRole.user).length})', style: secondaryTextStyle)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(() => _buildUserList(
                      controller.allUsers.where((u) => u.role == UserRole.admin).toList(),
                      isSuperAdmin,
                  )),
                  Obx(() => _buildUserList(
                      controller.allUsers.where((u) => u.role == UserRole.user).toList(),
                      true, 
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users, bool canModify) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('Bu kategoride kullanıcı bulunmamaktadır.', style: secondaryTextStyle.copyWith(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 3, 
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              backgroundColor: user.isBlocked ? blockedColor : activeColor,
              radius: 25,
              child: Icon(user.isBlocked ? Icons.lock : Icons.check, color: Colors.white, size: 24),
            ),
            // تطبيق الخط الجديد على العنوان
            title: Text('${user.name} ${user.surname}', style: secondaryTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email ?? user.username ?? 'Bilinmiyor', style: secondaryTextStyle.copyWith(fontSize: 14, color: Colors.black54)),
                Text('Durum: ${user.isBlocked ? 'BLOKE EDİLMİŞ' : 'AKTİF'}', 
                      style: secondaryTextStyle.copyWith(color: user.isBlocked ? blockedColor : activeColor, fontWeight: FontWeight.w600)),
                if (user.role == UserRole.user) 
                  Obx(() => _buildUserLocationInfo(user)), 
              ],
            ),
            trailing: canModify ? _buildAdminActions(user) : null,
          ),
        );
      },
    );
  }
  
  // عرض حالة الموقع (خاص باليوزرز)
  Widget _buildUserLocationInfo(UserModel user) {
    final location = controller.liveLocations[user.uid];
    bool isConnected = location != null && (location['isTracking'] == true || location['isTracking'] == 'true');
    
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: isConnected ? activeColor : blockedColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              isConnected ? 'Canlı Takipte' : 'Çevrimdışı (Son Konum: ${location?['timestamp']?.split(' ')[1] ?? 'Yok'})', 
              style: secondaryTextStyle.copyWith(fontSize: 12, color: isConnected ? activeColor : blockedColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          IconButton(
            icon: Icon(Icons.map_sharp, color: isConnected ? primaryColor : Colors.grey, size: 28),
            tooltip: 'Haritada Gör',
            onPressed: isConnected ? () {
              controller.viewUserOnMap(user.uid, location?['latitude'], location?['longitude']); 
            } : null,
          ),
        ],
      ),
    );
  }

  // أزرار التحكم في المستخدم (الحظر/الحذف)
  Widget _buildAdminActions(UserModel user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // زر الحظر / التفعيل
        IconButton(
          icon: Icon(user.isBlocked ? Icons.lock_open : Icons.lock, size: 28, color: user.isBlocked ? activeColor : blockedColor),
          tooltip: user.isBlocked ? 'Engeli Kaldır' : 'Bloke Et',
          onPressed: () => controller.toggleUserBlock(user, !user.isBlocked),
        ),
        // زر الحذف
        IconButton(
          icon: const Icon(Icons.delete_forever, size: 28, color: Colors.grey),
          tooltip: 'Kullanıcıyı Sil',
          onPressed: () => _confirmDelete(user),
        ),
      ],
    );
  }
  
  void _confirmDelete(UserModel user) {
    Get.defaultDialog(
      title: "Kullanıcı Silme Onayı",
      middleText: "${user.email} kullanıcısını sistemden kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.",
      textConfirm: "Sil",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      cancelTextColor: primaryColor,
      onConfirm: () {
        controller.deleteUser(user);
        Get.back(); 
      },
    );
  }
  
  // ويدجت مساعدة للـ Shimmer 
  Widget _buildLoadingDashboard() {
    // (لا حاجة لتغيير هنا، لأنها تستخدم الألوان البيضاء والرمادية الافتراضية للشيمر)
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 100, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)))),
              Expanded(child: Container(height: 100, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)))),
              Expanded(child: Container(height: 100, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)))),
            ],
          ),
          const SizedBox(height: 30),
          Container(height: 24, width: 300, color: Colors.white),
          const Divider(height: 20, thickness: 2),
          Container(
            height: Get.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => CustomShimmer.buildLoadingListTile(),
            ),
          )
        ],
      ),
    );
  }
}
