import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../controllers/admin_controller.dart'; 
import '../../controllers/auth_controller.dart'; 
import '../../widgets/custom_shimmer.dart'; 
import '../../widgets/elegant_hover_button.dart'; 
// استيراد ملف الـ Avatar الجديد
import '../../widgets/avatar_menu_widget.dart'; // <--- NEW IMPORT

class AdminHomeView extends GetView<AdminController> {
  const AdminHomeView({super.key});

  // الألوان الموحدة للتصميم الجديد (مطابقة لـ SignIn)
  static const Color primaryColor = Colors.black87; 
  static const Color secondaryColor = Color(0xFFFFC107); // Used for secondary elements/accents
  static const Color accentColor = Color(0xFFFFC107); // Alias for secondaryColor, for clarity in header
  static const Color successColor = Color(0xFF28A745); 
  static const Color blockedColor = Color(0xFFDC3545); 
  static const Color lightBackground = Color(0xFFF0F0F0); 


  // التعديل: استخدام static final لتعريف أنماط الخطوط
  static final TextStyle primaryTextStyle = GoogleFonts.playfairDisplay(color: primaryColor);
  static final TextStyle secondaryTextStyle = const TextStyle(color: Colors.black87);
  static final TextStyle accentTextStyle = GoogleFonts.playfairDisplay(color: accentColor);


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
    
    // Determine user role logic here, as it's needed for the header build
    final currentUser = authController.authService.currentUser.value;
    final userRole = currentUser?.role.toString().split('.').last.toUpperCase() ?? 'ADMIN'; 
    final isSuperAdmin = userRole == 'SUPERADMIN';
    
    return Scaffold(
      backgroundColor: lightBackground, 
      
      body: Column(
        children: [
          // Using the new elegant header
          _buildElegantHeader(isSuperAdmin, authController), 
          
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
    );
  }

  // ----------------------------------------------------
  // --- ELEGANT HEADER (Compact, Centered, with Avatar) ---
  // ----------------------------------------------------
  Widget _buildElegantHeader(bool isSuperAdmin, AuthController authController) {
    final currentUser = authController.authService.currentUser.value;
    final userName = currentUser?.name ?? 'Admin';
    final userRole = currentUser?.role.toString().split('.').last.toUpperCase() ?? 'ADMIN'; 
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      decoration: const BoxDecoration(
        color: primaryColor,
        // Removed bottom radius to make it look like a seamless top bar
      ),
      child: Stack(
        children: [
          // Menu Button (Top Right) - Now an elegant Avatar
          Align(
            alignment: Alignment.topRight,
            child: _buildAvatarMenu(isSuperAdmin, authController, userName, userRole),
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
                    // NOTE: CustomShimmer is likely intended for a loading state, 
                    // but applied here as per the request, which might be for an animated effect.
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
    );
  }
  
  // Widget for the Logo Content
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
          'MINIBUS ANALİZ', // Keeping the original text as 'MINIBUS ANALİZ'
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

  // Widget to build the Avatar Menu Button
  Widget _buildAvatarMenu(bool isSuperAdmin, AuthController authController, String userName, String userRole) {
    return IconButton(
      icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 30),
      onPressed: () {
        // Call the external function to show the modern dialog menu
        showModernUserMenu(
          Get.context!, // Using Get.context! as the context is generally available in a GetX app
          isSuperAdmin, 
          authController, 
          userName, 
          userRole,
        );
      },
    );
  }

  // ----------------------------------------------------
  // --- WIDGET BUILDERS (Unchanged from previous request) ---
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
                  prefixIcon: const Icon(Icons.schedule, color: secondaryColor), // الأيقونة باللون الذهبي
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
                  prefixIcon: const Icon(Icons.timer, color: secondaryColor), // الأيقونة باللون الذهبي
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
            // ElegantHoverButton بلون ذهبي أفتح
            child: ElegantHoverButton(
              onPressed: () => controller.uploadExcelFile(true),
              width: double.infinity, 
              backgroundColor: secondaryColor, // ذهبي كامل
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
        prefixIcon: const Icon(Icons.search, color: secondaryColor), // الأيقونة باللون الذهبي
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
            child: Text('Lütfen Excel dosyalarını yükleyıp analiz yapın.', style: secondaryTextStyle.copyWith(color: Colors.grey, fontSize: 16)),
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