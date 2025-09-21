// lib/views/admin/admin_home_view.dart 

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // لاستخدام خط Google Fonts
import '../../controllers/admin_controller.dart'; 
import '../../controllers/auth_controller.dart'; 
import '../../services/auth_service.dart'; 
import '../../data/models/user_model.dart';
import '../../widgets/custom_shimmer.dart'; 
import '../../widgets/elegant_hover_button.dart'; 

class AdminHomeView extends GetView<AdminController> {
  const AdminHomeView({super.key});

 // الألوان الموحدة للتصميم الجديد (مطابقة لـ SignIn)
  static const Color primaryColor = Colors.black87; 
  static const Color secondaryColor = Color(0xFFFFC107); 
  static const Color successColor = Color(0xFF28A745); 
  static const Color blockedColor = Color(0xFFDC3545); 
  static const Color lightBackground = Color(0xFFF0F0F0); 


  // التعديل: استخدام static final لتعريف أنماط الخطوط
  static final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
  static final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);


  // دالة مساعدة لتظليل نص البحث 
  List<TextSpan> _highlightSearchText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: secondaryTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold))];
    }
    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int start = 0;
    while (true) {
      int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: secondaryTextStyle));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: secondaryTextStyle));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: secondaryTextStyle.copyWith(
          backgroundColor: secondaryColor.withOpacity(0.5), 
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
    return Scaffold(
      backgroundColor: lightBackground, 
      
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(authController), 
            
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return CustomShimmer(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildLoadingCard()),
                          const SizedBox(width: 20),
                          Expanded(flex: 4, child: _buildLoadingCard()),
                        ],
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildStopManagementCard(context),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4, 
                        child: _buildAnalysisResultCard(),
                      ),
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
  // --- CUSTOM HEADER (AppBar البديل) المُعدَّل ---
  // ----------------------------------------------------
  Widget _buildCustomHeader(AuthController authController) {
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
              Icon(Icons.directions_bus_filled_rounded, color: secondaryColor, size: 30),
              const SizedBox(width: 10),
              Text(
                'MINIBUS ANALİZ', 
                style: primaryTextStyle.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.2))]
                ),
              ),
            ],
          ),
          
          // قائمة المستخدم الجديدة
          Row(
            children: [
              // زر الانتقال للوحة التحكم الرئيسية
              IconButton(
                icon: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
                tooltip: 'Yönetici Paneli',
                onPressed: () => Get.offNamed('/admin_dashboard'),
              ),
              
              const SizedBox(width: 10),
              
              // إضافة قائمة المستخدم المنبثقة (Burger Menu البديل)
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
                              backgroundColor: secondaryColor, // خلفية ذهبية
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
  // --- WIDGET BUILDERS ---
  // ----------------------------------------------------
  
  Widget _buildLoadingCard() {
    return Card(
      elevation: 8, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
      child: Padding(
        padding: const EdgeInsets.all(30.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 24, width: 250, color: Colors.white), 
            const Divider(height: 30, thickness: 2),
            Container(height: 50, color: Colors.white), 
            const SizedBox(height: 30),
            Container(height: 50, color: Colors.white), 
            const SizedBox(height: 30),
            Container(height: 18, width: 180, color: Colors.white), 
            const SizedBox(height: 15),
            Container(height: 150, color: Colors.white), 
            const SizedBox(height: 40),
            Container(height: 50, width: double.infinity, color: Colors.white), 
            const SizedBox(height: 10),
            Container(height: 60, width: double.infinity, color: Colors.white), 
          ],
        ),
      ),
    );
  }
  
  Widget _buildStopManagementCard(BuildContext context) {
    return Card(
      elevation: 8, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
      child: Padding(
        padding: const EdgeInsets.all(30.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Durak ve Zamanlama Yönetimi', style: primaryTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
            const Divider(height: 30, thickness: 2, color: primaryColor),
            
            _buildTimeSettings(),
            const SizedBox(height: 30),
            
            Text('Yeni Durak Ekle', style: secondaryTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildAddStopSection(),
            const SizedBox(height: 30),

            Text('Tanımlı Duraklar (${controller.stops.length}):', style: primaryTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 15),
            _buildStopList(),
            const SizedBox(height: 40),

            Text('Veri Yükleme ve Analiz', style: primaryTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
            const Divider(height: 30, thickness: 2, color: primaryColor),
            _buildFileUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField( 
                controller: controller.startTimeController,
                style: secondaryTextStyle, // تطبيق الخط
                decoration: InputDecoration(
                  labelText: 'İlk Kalkış (HH:MM)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.schedule, color: secondaryColor), // الأيقونة باللون الذهبي
                ),
                onChanged: (value) => controller.referenceStartTime.value = value,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: controller.intervalController,
                style: secondaryTextStyle, // تطبيق الخط
                decoration: InputDecoration(
                  labelText: 'Minibüs Aralığı (dk)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.timer, color: secondaryColor), // الأيقونة باللون الذهبي
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => controller.intervalBetweenBuses.value = int.tryParse(value) ?? 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05), // خلفية خفيفة جداً
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🚌 Başlangıç saati: ${controller.referenceStartTime.value}, Aralık: ${controller.intervalBetweenBuses.value} dk',
                style: secondaryTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
              ),
            )),
      ],
    );
  }

  Widget _buildAddStopSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: controller.stopNameController,
            style: secondaryTextStyle, // تطبيق الخط
            decoration: InputDecoration(
              labelText: 'Yeni Durak Adı',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controller.durationController,
            style: secondaryTextStyle, // تطبيق الخط
            decoration: InputDecoration(
              labelText: 'Süre (dk)',
              hintText: 'Örn: 12',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 15),
        // ElegantHoverButton باللون الأخضر
        ElegantHoverButton(
          onPressed: controller.addStop,
          text: 'Ekle',
          width: 120, 
          height: 50, 
          backgroundColor: successColor, 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Ekle', style: secondaryTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStopList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300), 
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Obx(() => ListView.builder(
            shrinkWrap: true,
            itemCount: controller.stops.length,
            itemBuilder: (context, index) {
              final stop = controller.stops[index];
              return ListTile(
                key: ValueKey(stop.name), 
                tileColor: index % 2 == 0 ? primaryColor.withOpacity(0.03) : Colors.white, // تظليل خفيف
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                leading: CircleAvatar(
                  backgroundColor: secondaryColor, // الأرقام باللون الذهبي
                  child: Text('${index + 1}', style: secondaryTextStyle.copyWith(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(stop.name, style: secondaryTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(index == 0 ? 'Başlangıç Durağı' : 'Önceki Duraktan Süre: ${stop.durationFromPrevious} dk', style: secondaryTextStyle.copyWith(color: Colors.black54)),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, color: blockedColor), 
                  onPressed: () => controller.removeStop(index),
                ),
              );
            },
          )),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر تحميل Gidiş (الذهاب)
        ElegantHoverButton(
          onPressed: () => controller.uploadExcelFile(false),
          width: double.infinity, 
          backgroundColor: primaryColor, // أسود داكن
          child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.drive_folder_upload, color: Colors.white),
              const SizedBox(width: 8),
              Text('Gidiş Excel Yükle (${controller.vehicleRecords.length} Kayıt)', 
                    style: secondaryTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          )),
        ),
        const SizedBox(height: 15),
        
        // مربع تحديد Dönüş
        Obx(() => CheckboxListTile(
              title: Text('Dönüş Seferlerini Dahil Et', style: secondaryTextStyle.copyWith(fontWeight: FontWeight.w600)),
              value: controller.includeReturn.value,
              onChanged: (value) => controller.includeReturn.value = value ?? false,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: secondaryColor, // تحديد بالذهبي
              contentPadding: EdgeInsets.zero,
            )),
            
        // زر تحميل Dönüş (العودة)
        Obx(() => Visibility(
              visible: controller.includeReturn.value,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                //  ElegantHoverButton بلون ذهبي أفتح
                child: ElegantHoverButton(
                  onPressed: () => controller.uploadExcelFile(true),
                  width: double.infinity, 
                  backgroundColor: secondaryColor, //  ذهبي كامل
                  child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file, color: primaryColor), // أيقونة بالأسود الداكن
                      const SizedBox(width: 8),
                      Text('Dönüş Excel Yükle (${controller.returnRecords.length} Kayıt)', 
                            style: secondaryTextStyle.copyWith(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  )),
                ),
              ),
            )),
        const SizedBox(height: 30),
        
        // زر التحليل
        Obx(() => ElegantHoverButton(
              onPressed: controller.analyzeDelays,
              text: controller.isAnalyzing.value ? null : 'Gecikme Analizi BAŞLAT',
              width: double.infinity, 
              height: 60, 
              backgroundColor: successColor, // أخضر للبدء
              child: controller.isAnalyzing.value 
                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text('Gecikme Analizi BAŞLAT', style: secondaryTextStyle.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
            )),
      ],
    );
  }

  Widget _buildAnalysisResultCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Analiz Sonuçları ve Raporlama', style: primaryTextStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
            const Divider(height: 30, thickness: 2, color: primaryColor),

            _buildSearchBox(),
            const SizedBox(height: 20),

            _buildPlateList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Obx(() => TextFormField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          style: secondaryTextStyle,
          decoration: InputDecoration(
            labelText: 'Plaka Ara',
            hintText: '35BNV175',
            prefixIcon: Icon(Icons.search, color: secondaryColor), // الأيقونة باللون الذهبي
            suffixIcon: controller.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => controller.searchController.clear(),
                  )
                : null,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ));
  }

  Widget _buildPlateList() {
    return Obx(() {
      final filteredPlates = controller.getUniqueVehiclePlates();
      
      if (controller.delayAnalyses.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text('Lütfen Excel dosyalarını yükleyıp تحليل yapın.', style: secondaryTextStyle.copyWith(color: Colors.grey, fontSize: 16)),
          ),
        );
      }

      return Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: filteredPlates.length,
          itemBuilder: (context, index) {
            String plateNumber = filteredPlates[index];
            var vehicleAnalyses = controller.delayAnalyses.where(
                    (analysis) => analysis.plateNumber == plateNumber).toList();

            int totalDelays = vehicleAnalyses.fold(0,
                    (sum, analysis) => sum + analysis.totalDelayMinutes);

            final color = totalDelays == 0 ? successColor : blockedColor;

            return Card(
              key: ValueKey(plateNumber),
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              elevation: 4, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                leading: CircleAvatar(
                  backgroundColor: color,
                  radius: 20,
                  child: Icon(
                    totalDelays == 0 ? Icons.check_circle_outline : Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: RichText(
                  text: TextSpan(
                    children: _highlightSearchText(plateNumber, controller.searchQuery.value),
                    style: secondaryTextStyle.copyWith(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Text(
                  totalDelays == 0
                      ? 'Gecikme yok (${vehicleAnalyses.length} Sefer)'
                      : 'Toplam Gecikme: $totalDelays dk',
                  style: secondaryTextStyle.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.picture_as_pdf, color: color, size: 28),
                    onPressed: () => controller.generatePDF(plateNumber),
                    tooltip: 'Raporu İndir',
                  ),
                ),
                onTap: () => controller.generatePDF(plateNumber),
              ),
            );
          },
        ),
      );
    });
  }
}
