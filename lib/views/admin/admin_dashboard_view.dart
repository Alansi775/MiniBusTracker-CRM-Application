// lib/views/admin/admin_dashboard_view.dart (Errors FIXED and Cleaned)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../controllers/admin_controller.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart'; 
import '../../controllers/auth_controller.dart'; 
import '../../widgets/custom_shimmer.dart'; 

// 🎨 COLORS: DEEP CHARCOAL, PURE GOLD, WHITE
class AdminDashboardView extends GetView<AdminController> {
  AdminDashboardView({super.key});

  // 1. REFINED COLOR PALETTE
  static const Color primaryColor = Color(0xFF1A1A1A); // أسود داكن (Deep Charcoal)
  static const Color accentColor = Color(0xFFFFD700); // ذهبي نقي (Pure Gold)
  static const Color activeColor = Color(0xFF28A745); // أخضر (Success)
  static const Color blockedColor = Color(0xFFDC3545); // أحمر (Error/Blocked)
  static const Color lightBackground = Color(0xFFF7F7F7); // خلفية خفيفة

  // 2. MODERN FONT: Exo 2 (Geometric Sans-serif)
  static final TextStyle primaryTextStyle = GoogleFonts.exo2(color: primaryColor);
  static final TextStyle accentTextStyle = GoogleFonts.exo2(color: accentColor);
  
  // Use an instance variable initialized with .obs for reactivity.
  RxInt _selectedTabIndex = 0.obs;
  static final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    // Controller instance is accessed via `controller` property inherited from GetView
    final currentUserRole = Get.find<AuthService>().currentUser.value?.role;
    final bool isSuperAdmin = currentUserRole == UserRole.superAdmin;
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: primaryColor, 
      body: Column(
        children: [
          // 3. ELEGANT HEADER (Centered Logo/Welcome with Avatar Menu)
          _buildElegantHeader(isSuperAdmin, authController),
          
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: lightBackground, 
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              // WRAPPING CONTENT IN A PageView FOR SWIPING
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  // Handle main page changes here
                },
                children: [
                  // PAGE 1: Main Dashboard Content
                  Obx(() {
                    if (controller.isLoading.value) {
                      return CustomShimmer(child: _buildLoadingDashboard(context));
                    }
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 4. SHOCKING STAT CARDS
                          _buildStatsRow(),
                          
                          const SizedBox(height: 40),
                          
                          Text(
                            'Kullanıcı Yönetim Merkezi', 
                            style: primaryTextStyle.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          const Divider(height: 10, thickness: 3, color: accentColor), 

                          const SizedBox(height: 20),
                          // 5. SEGMENTED CONTROL TABS
                          _buildUserSegmentedControl(isSuperAdmin),
                          
                          const SizedBox(height: 15),

                          // 6. GLASSMORPHIC LIST CONTAINER
                          Obx(() => _buildUserListContainer(isSuperAdmin)),
                        ],
                      ),
                    );
                  }),
                  
                  // Placeholder for another swipeable section (e.g., Reports)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('Diğer Bölümler için Hazırlanıyor... (Kaydırma Çalışıyor!)', style: TextStyle(fontSize: 20, color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // --- 3. ELEGANT HEADER (Compact, Centered, with Avatar) ---
  // ----------------------------------------------------
  Widget _buildElegantHeader(bool isSuperAdmin, AuthController authController) {
    final currentUser = authController.authService.currentUser.value;
    final userName = currentUser?.name ?? 'Admin';
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
        decoration: const BoxDecoration(
          color: primaryColor,
        ),
        child: Stack(
          children: [
            // Menu Button (Top Right) - Now an elegant Avatar
            Align(
              alignment: Alignment.topRight,
              child: _buildAvatarMenu(isSuperAdmin, authController, userName),
            ),

            // Logo and Welcome Text Group (CENTERED)
            Center(
              // Limiting the max width on large screens to keep the logo area compact
              child: SizedBox(
                width: 300, 
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and App Name
                      _buildElegantLogoContent(),

                      const SizedBox(height: 10),

                      // Personalized Welcome Message
                      CustomShimmer(
                        child: Text(
                          'Hoş Geldin, $userName', 
                          style: accentTextStyle.copyWith(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget from the User's Request (Logo content)
  Widget _buildElegantLogoContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الأيقونة الذهبية البارزة 
        Icon(
          Icons.directions_bus_filled_rounded,
          size: 36,
          color: accentColor,
        ),
        const SizedBox(height: 5),
        // النص بدون 'fontWeight' ليكون ناعماً
        Text(
          'MİNİBÜSCRM',
          style: GoogleFonts.playfairDisplay(
              fontSize: 24, 
              color: accentColor,
              height: 1,
          ),
        ),
        // تاق أو خط فاصل للتأكيد
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Container(
            width: 80, 
            height: 2, // Reduced height
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  // Helper function for the menu - With modern hover effects and Turkish tooltip
  Widget _buildAvatarMenu(bool isSuperAdmin, AuthController authController, String userName) {
    final userRole = Get.find<AuthService>().currentUser.value?.role.toString().split('.').last.toUpperCase() ?? 'ADMIN';
    
    return Builder(
      builder: (BuildContext context) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: '• Hesap Menüsü', // Turkish tooltip
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textStyle: GoogleFonts.exo2(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            waitDuration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                hoverColor: accentColor.withOpacity(0.1),
                splashColor: accentColor.withOpacity(0.2),
                highlightColor: accentColor.withOpacity(0.1),
                onTap: () {
                  _showModernMenu(context, isSuperAdmin, authController, userName, userRole);
                },
                child: Container(
                  width: 48, // Slightly larger for better tap target
                  height: 48, // Slightly larger for better tap target
                  padding: const EdgeInsets.all(2.0), // Padding for the golden border
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: accentColor, width: 2.5), // Prominent golden border
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person, // Generic user icon (Avatar)
                      color: primaryColor, // Icon color (Deep Charcoal)
                      size: 28, // Sized to fit perfectly inside
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Modern custom menu with glassmorphism and animations
  void _showModernMenu(BuildContext context, bool isSuperAdmin, AuthController authController, String userName, String userRole) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.2),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return Container();
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.2, -0.3),
            end: const Offset(0.0, 0.0),
          ).animate(CurvedAnimation(
            parent: animation1,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation1,
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(top: 90, right: 20),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: accentColor.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with user info
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.05),
                                    accentColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.person, color: accentColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: primaryTextStyle.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: accentColor.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                userRole,
                                                style: primaryTextStyle.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Menu Items
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  if (isSuperAdmin)
                                    _buildModernMenuItem(
                                      icon: Icons.pending_actions_rounded,
                                      title: 'Bekleyen İstekler',
                                      subtitle: 'Yeni kayıt onayları',
                                      iconColor: Colors.orange,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Get.toNamed('/pending_requests');
                                      },
                                    ),
                                  
                                  _buildModernMenuItem(
                                    icon: Icons.lock_reset_rounded,
                                    title: 'Şifre Değiştir',
                                    subtitle: 'Güvenlik ayarları',
                                    iconColor: Colors.blue,
                                    onTap: () {
                                      Navigator.pop(context);
                                      Get.toNamed('/change_password');
                                    },
                                  ),
                                  
                                  // Divider
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.grey.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  _buildModernMenuItem(
                                    icon: Icons.logout_rounded,
                                    title: 'Çıkış Yap',
                                    subtitle: 'Hesabından çık',
                                    iconColor: blockedColor,
                                    isDestructive: true,
                                    onTap: () {
                                      Navigator.pop(context);
                                      authController.signOut();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Modern menu item with hover effects - Consolidated definition
  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDestructive 
              ? blockedColor.withOpacity(0.05)
              : primaryColor.withOpacity(0.05),
          splashColor: isDestructive
              ? blockedColor.withOpacity(0.1)
              : accentColor.withOpacity(0.1),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: primaryTextStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? blockedColor : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: primaryTextStyle.copyWith(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ----------------------------------------------------
  // --- 4. SHOCKING STAT CARDS (Minimalist/Gold) - CONSOLIDATED ---
  // ----------------------------------------------------
  Widget _buildStatsRow() {
    return Obx(() {
      final adminsCount = controller.allUsers.where((u) => u.role == UserRole.admin).length;
      final usersCount = controller.allUsers.where((u) => u.role == UserRole.user).length;
      final pendingCount = controller.pendingUsers.length;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildStatCard(
              title: 'Yöneticiler', 
              count: adminsCount, 
              icon: Icons.shield_sharp, 
              color: primaryColor,
              delay: 0,
          )),
          Expanded(child: _buildStatCard(
              title: 'Müşteriler', 
              count: usersCount, 
              icon: Icons.people_alt, 
              color: activeColor,
              delay: 200,
          )),
          Expanded(child: _buildStatCard(
              title: 'Bekleyenler', 
              count: pendingCount, 
              icon: Icons.pending_actions, 
              color: accentColor,
              delay: 400,
          )),
        ],
      );
    });
  }

  Widget _buildStatCard({required String title, required int count, required IconData icon, required Color color, required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * value,
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 15 * value,
                      offset: Offset(0, 8 * value),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: primaryTextStyle.copyWith(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withOpacity(0.5), width: 1),
                            ),
                            child: Icon(icon, size: 20, color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        count.toString(),
                        style: accentTextStyle.copyWith(fontSize: 34, fontWeight: FontWeight.w900, color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // --- 5. SEGMENTED CONTROL (Custom Tabs) ---
  // ----------------------------------------------------
  Widget _buildUserSegmentedControl(bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSegmentButton(
            label: 'Yöneticiler',
            count: controller.allUsers.where((u) => u.role == UserRole.admin).length,
            index: 0,
          ),
          _buildSegmentButton(
            label: 'Müşteriler', 
            count: controller.allUsers.where((u) => u.role == UserRole.user).length,
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({required String label, required int count, required int index}) {
    return Obx(() {
      final isSelected = _selectedTabIndex.value == index;
      return Expanded(
        child: InkWell(
          onTap: () => _selectedTabIndex.value = index,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ] : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$label ($count)',
              style: primaryTextStyle.copyWith(
                color: isSelected ? Colors.white : primaryColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    });
  }

  // ----------------------------------------------------
  // --- 6. GLASSMORPHIC LIST CONTAINER ---
  // ----------------------------------------------------
  Widget _buildUserListContainer(bool isSuperAdmin) {
    // Correctly using the instance variable `_selectedTabIndex`
    final List<UserModel> users = _selectedTabIndex.value == 0
        ? controller.allUsers.where((u) => u.role == UserRole.admin).toList()
        : controller.allUsers.where((u) => u.role == UserRole.user).toList();
    
    // Glassmorphism effect
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: Get.height * 0.45,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7), // Subtle transparency
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _buildUserList(users, isSuperAdmin),
        ),
      ),
    );
  }

  // Updated List (now inside the glass container)
  Widget _buildUserList(List<UserModel> users, bool canModify) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('Bu kategoride kullanıcı bulunmamaktadır.', style: primaryTextStyle.copyWith(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.isBlocked ? blockedColor : accentColor,
                ),
                child: Icon(user.isBlocked ? Icons.block : Icons.check_circle_outline, color: Colors.white, size: 24),
              ),
              title: Text('${user.name} ${user.surname}', style: primaryTextStyle.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email ?? user.username ?? 'Bilinmiyor', style: primaryTextStyle.copyWith(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 5),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.isBlocked ? blockedColor.withOpacity(0.15) : activeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      user.isBlocked ? 'BLOKE EDİLMİŞ' : 'AKTİF', 
                      style: primaryTextStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: user.isBlocked ? blockedColor : activeColor),
                    ),
                  ),
                  if (user.role == UserRole.user) 
                    Obx(() => _buildUserLocationInfo(user)), 
                ],
              ),
              trailing: canModify ? _buildAdminActions(user) : null,
            ),
          ),
        );
      },
    );
  }
  
  // Location Info - Enhanced visibility for map button (RE-ADDED)
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
              isConnected ? 'Canlı Takipte' : 'Çevrimdışı', 
              style: primaryTextStyle.copyWith(fontSize: 12, color: isConnected ? activeColor : blockedColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          IconButton(
            icon: Icon(Icons.map_sharp, color: isConnected ? accentColor : Colors.grey.shade400, size: 28),
            tooltip: 'Haritada Gör',
            onPressed: isConnected ? () {
              // The `location` map stores values as `dynamic`, so we explicitly cast to `double`
              controller.viewUserOnMap(user.uid, location!['latitude'] as double, location!['longitude'] as double); 
            } : null,
          ),
        ],
      ),
    );
  }

  // Admin Actions - Cleaned up icon buttons (RE-ADDED)
  Widget _buildAdminActions(UserModel user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(user.isBlocked ? Icons.lock_open : Icons.lock, size: 26, color: user.isBlocked ? activeColor : blockedColor),
          tooltip: user.isBlocked ? 'Engeli Kaldır' : 'Bloke Et',
          onPressed: () => controller.toggleUserBlock(user, !user.isBlocked),
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded, size: 26, color: Colors.grey),
          tooltip: 'Kullanıcıyı Sil',
          onPressed: () => _confirmDelete(user),
        ),
      ],
    );
  }
  
  // Dialog (RE-ADDED)
  void _confirmDelete(UserModel user) {
    Get.defaultDialog(
      title: "Kullanıcı Silme Onayı",
      middleText: "${user.name} kullanıcısını sistemden kalıcı olarak silmek istediğinizden emin misiniz?",
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
  
  // Shimmer Widget - Now matching the new layout structure (RE-ADDED)
  Widget _buildLoadingDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Shimmer
          Row(
            children: [
              Expanded(child: Container(height: 100, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              Expanded(child: Container(height: 100, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              Expanded(child: Container(height: 100, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
          const SizedBox(height: 40),
          // Title Shimmer
          Container(height: 28, width: 300, color: Colors.white),
          const Divider(height: 20, thickness: 2),
          // Segmented Control Shimmer
          Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15))),
          const SizedBox(height: 15),
          // List Container Shimmer
          Container(
            height: Get.height * 0.45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              itemCount: 5,
              // Correctly calling the method on the CustomShimmer class
              itemBuilder: (context, index) => CustomShimmer.buildLoadingListTile(),
            ),
          )
        ],
      ),
    );
  }
}