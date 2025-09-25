// lib/widgets/avatar_menu_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../controllers/auth_controller.dart'; // Ensure correct path to AuthController

// --- Shared Constants (Must be defined here for standalone widget) ---
const Color primaryColor = Colors.black87; 
const Color accentColor = Color(0xFFFFC107); // Using the same golden color as secondaryColor
const Color blockedColor = Color(0xFFDC3545); 

// Shared Text Styles
final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);
// -------------------------------------------------------------------


// Helper Widget for Menu Items
Widget _buildModernMenuItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color iconColor,
  required VoidCallback onTap,
  bool isDestructive = false,
}) {
  final color = isDestructive ? blockedColor : primaryColor;
  return InkWell(
    onTap: onTap,
    hoverColor: iconColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(15),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: secondaryTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: secondaryTextStyle.copyWith(
                  fontSize: 11,
                  color: color.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


// Main Function to Display the Modern Menu
void showModernUserMenu(
  BuildContext context, 
  bool isSuperAdmin, 
  AuthController authController, 
  String userName, 
  String userRole
) {
  // Ensure the navigator pops to close the menu
  void handleTap(String route) {
    Navigator.pop(context);
    Get.toNamed(route);
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
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
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: accentColor, 
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'A', 
                                        style: secondaryTextStyle.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
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
                                    onTap: () => handleTap('/pending_requests'),
                                  ),
                                
                                _buildModernMenuItem(
                                  icon: Icons.lock_reset_rounded,
                                  title: 'Şifre Değiştir',
                                  subtitle: 'Güvenlik ayarları',
                                  iconColor: Colors.blue,
                                  onTap: () => handleTap('/change_password'),
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