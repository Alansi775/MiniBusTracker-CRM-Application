// lib/views/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart'; // لغرض الوصول إلى حالة المستخدم
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // الألوان الموحدة (يمكنك استيرادها من ملف الألوان الثابتة إذا كان لديك)
  static const Color primaryColor = Colors.black87; 
  static const Color accentColor = Color(0xFFFFC107); 

  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  void _checkAuthAndRedirect() async {
    // 1. تأخير آمن لتجنب مشكلة التنافس في الويب (1.5 ثانية)
    await Future.delayed(const Duration(milliseconds: 1500)); 

    // 2. التحقق من حالة المستخدم النهائية
    final currentUser = _authService.currentUser.value; 

    // 3. استدعاء التحويل (يفترض أن هذه الدالة موجودة في AuthController)
    _authController.redirectToHome(currentUser);
  }

  @override
  Widget build(BuildContext buildContext) {
    return Scaffold(
      backgroundColor: primaryColor, // خلفية داكنة فاخرة
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة بارزة (ذهب على أسود)
            Icon(
              Icons.directions_bus_filled_rounded,
              size: 80,
              color: accentColor, 
            ),
            const SizedBox(height: 10),
            // اسم التطبيق بخط أنيق
            Text(
              'MINIBUS ANALİZ', 
              style: GoogleFonts.playfairDisplay(
                fontSize: 30, 
                color: Colors.white, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            // مؤشر التحميل بلون التمييز
            SizedBox(
              width: 35,
              height: 35,
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 4, 
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Yükleniyor...', 
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}