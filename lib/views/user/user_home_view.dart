// lib/views/user/user_home_view.dart (الإصدار الاحترافي والنهائي الموحد)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// 💡 استيراد Google Fonts
import 'package:google_fonts/google_fonts.dart'; 
import '../../controllers/auth_controller.dart'; 
import '../../controllers/bus_controller.dart'; 
import '../../widgets/custom_shimmer.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

class UserHomeView extends GetView<BusController> { 
  const UserHomeView({super.key});

  // 🚨 الألوان الموحدة (الأسود الداكن والذهبي)
  static const Color primaryColor = Colors.black87; // أسود داكن (Brand)
  static const Color accentColor = Color(0xFFFFC107); // ذهبي (Action)
  
  // تدرجات ألوان الحالة الأكثر هدوءًا
  static const Color activeColor = Color(0xFF28A745); // أخضر هادئ (للحالة النشطة)
  static const Color stoppedColor = Color(0xFFDC3545); // أحمر نبيذي (للحالة المتوقفة)
  static const Color backgroundColor = Color(0xFFF0F0F0); 

  // 🚨 تعريف أنماط الخطوط
  static final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
  static final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);

  // دالة مساعدة لضمان سلامة الـ timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is FieldValue || timestamp == null) {
      return 'Şimdi';
    }
    if (timestamp is String && timestamp.contains(' ')) {
      try {
        return timestamp.split(' ')[1];
      } catch (_) {
        return timestamp; 
      }
    }
    return 'Şimdi'; 
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final userName = authController.authService.currentUser.value?.name ?? 'Sürücü';
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(authController),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Center( 
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 550), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        
                        _buildWelcomeBanner(userName),

                        const SizedBox(height: 50),
                        
                        Obx(() => _buildTrackingStatus(context, controller.isTracking.value, controller.currentLocation.value)),
                        
                        const SizedBox(height: 50),

                        Obx(() => _buildTrackingButton()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // --- WELCOME BANNER ---
  // ----------------------------------------------------
  Widget _buildWelcomeBanner(String userName) {
    final fullText = 'Hoş Geldiniz, $userName';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: CustomShimmer(
        child: Text(
          fullText,
          textAlign: TextAlign.center,
          // 🚨 تطبيق الخط الجديد واللون الأساسي
          style: primaryTextStyle.copyWith(
            fontSize: 24, // زيادة الحجم قليلاً ليتناسب مع الخط الجديد
            fontWeight: FontWeight.w800, 
            color: primaryColor, 
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // --- TRACKING STATUS WIDGET ---
  // ----------------------------------------------------
  Widget _buildTrackingStatus(BuildContext context, bool isTracking, Map<String, dynamic> location) {
    final statusText = isTracking ? 'AKTİF' : 'DURDURULDU';
    final statusColor = isTracking ? activeColor : stoppedColor;
    final isLoadingLocation = isTracking && location.isEmpty; 
    
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2), 
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // 1. العنوان والحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTracking ? Icons.location_on : Icons.location_off,
                color: statusColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              // 🚨 تطبيق الخط الجديد
              Text(
                'TAKİP DURUMU: $statusText',
                style: primaryTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w900, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // 2. عرض بيانات الموقع (شيمر أو بيانات)
          if (isLoadingLocation)
             CustomShimmer(
                child: Column(
                  children: [
                    Container(height: 15, width: 120, color: Colors.white, margin: const EdgeInsets.only(top: 8)),
                    Container(height: 15, width: 180, color: Colors.white, margin: const EdgeInsets.only(top: 4)),
                  ],
                ),
             )
          else if (isTracking && location.isNotEmpty)
            Column(
              children: [
                const Divider(thickness: 1, color: Colors.grey), 
                const SizedBox(height: 10),
                // 🚨 تطبيق الخط الجديد
                Text('SON KONUM BİLGİSİ:', style: secondaryTextStyle.copyWith(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                isWideScreen
                    ? _buildWideLocationDisplay(location)
                    : _buildNarrowLocationDisplay(location),
                
                const SizedBox(height: 10),
                // 🚨 تطبيق الخط الجديد
                Text(
                  'Güncelleme Saati: ${_formatTimestamp(location['timestamp'])}', 
                  style: secondaryTextStyle.copyWith(fontSize: 12, color: Colors.grey.shade600)),
              ],
            )
          else 
            // 🚨 تطبيق الخط الجديد
            Text(
              'Konum takibi şu anda devre dışı.', 
              style: secondaryTextStyle.copyWith(fontSize: 16, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // --- LOCATION DISPLAY WIDGETS ---
  // ----------------------------------------------------

  // ويدجت مساعدة لشكل الـ Chip الأنيق
  Widget _buildLocationChip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          // 🚨 تطبيق الخط الجديد
          Text(title, style: secondaryTextStyle.copyWith(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          // 🚨 تطبيق الخط الجديد
          Text(value, style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w900, color: primaryColor)), 
        ],
      ),
    );
  }
  
  Widget _buildNarrowLocationDisplay(Map<String, dynamic> location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, 
      children: [
        _buildLocationChip('ENLEM (Lat)', location['latitude'].toStringAsFixed(6), primaryColor),
        const SizedBox(height: 10), 
        _buildLocationChip('BOYLAM (Lon)', location['longitude'].toStringAsFixed(6), primaryColor),
      ],
    );
  }

  Widget _buildWideLocationDisplay(Map<String, dynamic> location) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildLocationChip('ENLEM (Lat)', location['latitude'].toStringAsFixed(6), primaryColor)),
        const SizedBox(width: 20),
        Expanded(child: _buildLocationChip('BOYLAM (Lon)', location['longitude'].toStringAsFixed(6), primaryColor)),
      ],
    );
  }
  
  // ----------------------------------------------------
  // --- TRACKING BUTTON WIDGET ---
  // ----------------------------------------------------
  Widget _buildTrackingButton() {
    final isTracking = controller.isTracking.value;
    final buttonColor = isTracking ? stoppedColor : accentColor;
    final textColor = isTracking ? Colors.white : primaryColor; 

    return SizedBox(
      width: 280, // زيادة العرض قليلاً
      height: 55, // زيادة الارتفاع
      child: ElevatedButton.icon(
        onPressed: isTracking
            ? controller.stopTracking
            : controller.startTracking,
        icon: Icon(
          isTracking ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          size: 26,
          color: textColor,
        ),
        label: Text(
          isTracking ? 'Takibi Durdur' : 'Takibi BAŞLAT',
          // 🚨 تطبيق الخط الجديد
          style: secondaryTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // حواف أكثر انسجاماً
          elevation: 7, // ظل أوضح
        ),
      ),
    );
  }
  
  // ----------------------------------------------------
  // --- CUSTOM HEADER ---
  // ----------------------------------------------------
  Widget _buildCustomHeader(AuthController authController) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.bus_alert_rounded, color: accentColor, size: 30), // 🚨 أيقونة بالذهبي
              const SizedBox(width: 10),
              // 🚨 تطبيق الخط الجديد
              Text(
                'SÜRÜCÜ PANELİ', 
                style: primaryTextStyle.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 28),
                tooltip: 'Şifre Değiştir',
                onPressed: () => Get.toNamed('/change_password'), 
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
                tooltip: 'Çıkış Yap',
                onPressed: authController.signOut, 
              ),
            ],
          ),
        ],
      ),
    );
  }
}