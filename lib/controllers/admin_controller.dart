import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart'; 

//  تأكد من وجود هذين الملفين في مساراتهما
import '../data/models/user_model.dart'; 
import '../services/auth_service.dart';

// -------------------------------------------------------------------
// --- DATA MODELS (لتحليل التأخيرات - تم وضعها هنا مؤقتاً لتجنب أخطاء imports) ---
// -------------------------------------------------------------------

class Stop {
  String name;
  int durationFromPrevious; 
  Stop({required this.name, required this.durationFromPrevious});
}
class VehicleRecord {
  String plateNumber;
  String date;
  List<String> arrivalTimes;
  VehicleRecord({required this.plateNumber, required this.date, required this.arrivalTimes});
}
class StopDelay {
  String stopName;
  int delayMinutes;
  String expectedTime;
  String actualTime;
  StopDelay({required this.stopName, required this.delayMinutes, required this.expectedTime, required this.actualTime});
}
class DelayAnalysis {
  String plateNumber;
  String tripTime;
  int totalDelayMinutes;
  List<StopDelay> stopDelays;
  bool isReturn;
  DelayAnalysis({required this.plateNumber, required this.tripTime, required this.totalDelayMinutes, required this.stopDelays, this.isReturn = false});
}

// -------------------------------------------------------------------
// --- ADMIN CONTROLLER (الدمج النهائي) ---
// -------------------------------------------------------------------

class AdminController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  
  // ===============================================
  // === خصائص إدارة المستخدمين ===
  // ===============================================
  final pendingUsers = <UserModel>[].obs;
  final isFetchingRequests = false.obs;
  final approvalRoles = [UserRole.admin, UserRole.user].obs; 
  final allUsers = <UserModel>[].obs;
  final liveLocations = <String, Map<String, dynamic>>{}.obs; 
  
  // ===============================================
  // === خصائص تحليل التأخيرات ===
  // ===============================================
  final stops = <Stop>[].obs;
  final vehicleRecords = <VehicleRecord>[].obs; 
  final returnRecords = <VehicleRecord>[].obs;  
  final includeReturn = false.obs;
  final delayAnalyses = <DelayAnalysis>[].obs;
  final searchQuery = "".obs;
  final isLoading = false.obs;
  final isAnalyzing = false.obs;

  final referenceStartTime = "06:30".obs;
  final intervalBetweenBuses = 30.obs; 

  final stopNameController = TextEditingController();
  final durationController = TextEditingController();
  final startTimeController = TextEditingController(text: "06:30");
  final intervalController = TextEditingController(text: "30");
  final searchController = TextEditingController();

  // ----------------------------------------------------
  // --- LIFECYCLE AND INITIALIZATION ---
  // ----------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    // بدأ الاستماع لطلبات التسجيل المعلقة 
    _fetchPendingRequests();
    // بدأ الاستماع لجميع المستخدمين وحالتهم الآنية
    _startUserAndLocationListeners();
    // ربط المتحكمات النصية بالمتغيرات القابلة للملاحظة
    ever(referenceStartTime, (value) => startTimeController.text = value);
    ever(intervalBetweenBuses, (value) => intervalController.text = value.toString());
  }

  // دالة لبدء الاستماع لكل المستخدمين والمواقع
  void _startUserAndLocationListeners() {
     // 1. الاستماع لجميع المستخدمين (Admin, User)
    _db.collection('users')
        // استماع لـ admin و user فقط، مع استبعاد superAdmin و pending
        .where('role', whereIn: [UserRole.admin.name, UserRole.user.name])
        .snapshots()
        .listen((snapshot) {
            allUsers.value = snapshot.docs
                .map((doc) => UserModel.fromMap(doc.data()))
                .toList();
        });
        
     // 2. الاستماع لمواقع الباصات (لخاصية "متصل/غير متصل" وآخر موقع)
     _db.collection('bus_locations')
        .snapshots()
        .listen((snapshot) {
            Map<String, Map<String, dynamic>> tempLocations = {};
            for (var doc in snapshot.docs) {
              tempLocations[doc.id] = doc.data();
            }
            liveLocations.value = tempLocations;
        });
  }

  // ----------------------------------------------------
  // --- USER MANAGEMENT LOGIC (الإدارة والتحكم) ---
  // ----------------------------------------------------

  void _fetchPendingRequests() {
    isFetchingRequests.value = true;
    _db.collection('users')
        .where('role', isEqualTo: UserRole.pending.name) 
        .orderBy('email', descending: false)
        .snapshots()
        .listen((snapshot) {
            pendingUsers.value = snapshot.docs
                .map((doc) => UserModel.fromMap(doc.data()))
                .toList();
            isFetchingRequests.value = false;
        }, onError: (error) {
            isFetchingRequests.value = false;
            // يتم إظهار الخطأ في واجهة المستخدم (PendingRequestsView)
            // Get.snackbar('Hata', 'Bekleyen istekler getirilirken hata oluştu.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
        });
  }

  Future<void> approveRequest(UserModel user, UserRole assignedRole) async {
    if (assignedRole == UserRole.superAdmin || assignedRole == UserRole.pending) {
       Get.snackbar('Hata', 'Geçersiz rol seçimi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
       return;
    }
    
    try {
      await _db.collection('users').doc(user.uid).update({
        'isApproved': true, 
        'role': assignedRole.name, 
        'mustChangePassword': false, 
      });
      
      _showModernToast(
        'Başarılı', 
        '${user.email} onaylandı ve ${assignedRole.name} rolü atandı.', 
        isSuccess: true
      );

    } catch (e) {
      Get.snackbar('Hata', 'Onaylama başarısız oldu: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  Future<void> rejectRequest(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).delete();
      
      _showModernToast(
        'Başarılı', 
        '${user.email} isteği reddedildi.', 
        isSuccess: true
      );

    } catch (e) {
      Get.snackbar('Hata', 'Reddetme başarısız oldu: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }

  // الحظر / التفعيل
  Future<void> toggleUserBlock(UserModel user, bool isBlocked) async {
    try {
      await _db.collection('users').doc(user.uid).update({
        'isBlocked': isBlocked,
      });
      _showModernToast(
        'Başarılı',
        '${user.name} kullanıcısının durumu güncellendi.',
        isSuccess: true
      );

    } catch (e) {
     // Get.snackbar('Hata', 'Kullanıcı durumu güncellenemedi: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      // New Modern Message appears here
      _showModernToast(
        'Hata',
        'Kullanıcı durumu güncellenemedi: $e',
        isSuccess: false
      );
    }
  }

  // حذف المستخدم
  Future<void> deleteUser(UserModel user) async {
    try {
      // 1. حذف الموقع من bus_locations (إذا كان user)
      if (user.role == UserRole.user) {
        await _db.collection('bus_locations').doc(user.uid).delete();
      }
      
      // 2. حذف المستخدم من Firestore
      await _db.collection('users').doc(user.uid).delete();
      
      // ملاحظة: حذف المستخدم من Firebase Auth يتطلب Server/Admin SDK
      // سنعتمد على أن التطبيق يتجاهل المستخدم المحذوف من Firestore.
      
      // Get.snackbar('Başarılı', '${user.email} sistemden silindi.', 
      //              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
      // New Modern message appears here 
      _showModernToast(
        'Başarılı',
        '${user.name} sistemden kalıcı olarak silindi.',
        isSuccess: true
      );

    } catch (e) {
    //  Get.snackbar('Hata', 'Kullanıcı silinemedi: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    // New Modern Message appears here
    _showModernToast(
      'Hata',
      'Kullanıcı silinemedi: $e',
      isSuccess: false
      );
    }
  }


void _showModernToast(String title, String message, {required bool isSuccess}) {
  // Define Colors and Icons based on success state
  final Color accentColor = isSuccess ? Colors.green.shade600 : Colors.red.shade600;
  final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
  
  // 1. Create the Custom Content Widget (The "Floating Card")
  final Widget toastContent = Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Material(
      color: Colors.white.withOpacity(0.95), // Translucent effect
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(14), 
        
        constraints: const BoxConstraints(
          maxWidth: 340, // Balanced width
        ),
        
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Accent Icon
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 12),
            
            // Text Content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Message (*** KEY FIX HERE: ALLOWING 2 LINES ***)
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 2, // <--- CHANGED FROM 1 TO 2
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Subtle Close Icon
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.close, color: Colors.black26, size: 16),
            ),
          ],
        ),
      ),
    ),
  );

  // 2. Show the Snackbar
  Get.snackbar(
    '', '', 
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(milliseconds: 1500),
    isDismissible: true,
    
    // Custom Widget Placement and Suppression:
    titleText: const SizedBox.shrink(),
    messageText: Center(child: toastContent), 
    
    // Aesthetic cleanup:
    backgroundColor: Colors.transparent, 
    boxShadows: const [],
    padding: EdgeInsets.zero,
    margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
    barBlur: 0,
    overlayBlur: 0,

    // Animation settings:
    forwardAnimationCurve: Curves.easeOutCubic,
    reverseAnimationCurve: Curves.easeInCubic,
    animationDuration: const Duration(milliseconds: 300), 
    
    // Suppress remaining default GetX elements
    icon: const SizedBox.shrink(),
    shouldIconPulse: false,
    mainButton: null,
  );
}

  // عرض الموقع على الخريطة (URL Launcher)
  void viewUserOnMap(String userId, double? lat, double? lng) async {
    if (lat == null || lng == null) {
      Get.snackbar('Hata', 'Kullanıcının canlı konumu mevcut değil.', 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
      return;
    }
    
    // استخدام Google Maps URL لفتح الموقع
    final url = 'http://maps.google.com/?q=$lat,$lng';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Hata', 'Harita uygulaması başlatılamadı.', 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }


  // ----------------------------------------------------
  // --- DURAK MANAGEMENT (إدارة المحطات) ---
  // ----------------------------------------------------

  void addStop() {
    if (stopNameController.text.isNotEmpty && durationController.text.isNotEmpty) {
      final duration = int.tryParse(durationController.text) ?? 0;
      stops.add(Stop(
        name: stopNameController.text.trim(),
        durationFromPrevious: duration,
      ));
      stopNameController.clear();
      durationController.clear();
    }
  }

  void removeStop(int index) {
    stops.removeAt(index);
  }

  // ----------------------------------------------------
  // --- FILE UPLOAD (تحميل ملف Excel) ---
  // ----------------------------------------------------
  
  Future<void> uploadExcelFile(bool isReturnFile) async {
    isLoading.value = true;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result != null && result.files.single.bytes != null) {
      try {
        var bytes = result.files.single.bytes!;
        var excel = Excel.decodeBytes(bytes);
        List<VehicleRecord> records = [];

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          for (int row = 1; row < sheet.maxRows; row++) {
            var cells = sheet.rows[row];
            if (cells.isNotEmpty && cells.length >= 3) {
              String plateNumber = cells[0]?.value?.toString() ?? '';
              String date = cells[1]?.value?.toString() ?? '';
              List<String> arrivalTimes = [];
              for (int col = 2; col < cells.length; col++) {
                if (cells[col]?.value != null) {
                  arrivalTimes.add(cells[col]!.value.toString());
                }
              }
              if (plateNumber.isNotEmpty && arrivalTimes.isNotEmpty) {
                records.add(VehicleRecord(
                  plateNumber: plateNumber,
                  date: date,
                  arrivalTimes: arrivalTimes,
                ));
              }
            }
          }
        }
        if (isReturnFile) {
          returnRecords.value = records;
        } else {
          vehicleRecords.value = records;
        }
        Get.snackbar('Başarılı', 'Excel dosyası başarıyla yüklendi (${records.length} kayıt).', 
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);

      } catch (e) {
        Get.snackbar('Hata', 'Dosya okuma hatası: $e', 
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      }
    }
    isLoading.value = false;
  }

  // ----------------------------------------------------
  // --- DELAY ANALYSIS LOGIC (منطق التحليل) ---
  // ----------------------------------------------------

  int _calculateTimeDifference(String time1, String time2) {
    List<String> time1Parts = time1.split(':');
    List<String> time2Parts = time2.split(':');
    
    if (time1Parts.length < 2 || time2Parts.length < 2) return 0;

    int hours1 = int.parse(time1Parts[0]);
    int minutes1 = int.parse(time1Parts[1]);
    
    int hours2 = int.parse(time2Parts[0]);
    int minutes2 = int.parse(time2Parts[1]);

    int totalMinutes1 = hours1 * 60 + minutes1;
    int totalMinutes2 = hours2 * 60 + minutes2;

    return totalMinutes2 - totalMinutes1;
  }
  
  String _addMinutesToTime(String time, int minutes) {
    List<String> parts = time.split(':');
    if (parts.length < 2) return time;
    
    int hours = int.parse(parts[0]);
    int mins = int.parse(parts[1]);

    int totalMinutes = hours * 60 + mins + minutes;
    int newHours = (totalMinutes ~/ 60) % 24;
    int newMins = totalMinutes % 60;

    return '${newHours.toString().padLeft(2, '0')}:${newMins.toString().padLeft(2, '0')}';
  }

  String _calculateReferenceStartTimeForRecord(int rowIndex) {
    return _addMinutesToTime(referenceStartTime.value, rowIndex * intervalBetweenBuses.value);
  }

  void analyzeDelays() {
    if (stops.isEmpty || vehicleRecords.isEmpty) {
      Get.snackbar('Hata', 'Önce durakları ve Excel dosyasını yükleyin!', 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
      return;
    }

    isAnalyzing.value = true;
    
    referenceStartTime.value = startTimeController.text;
    intervalBetweenBuses.value = int.tryParse(intervalController.text) ?? 30;

    delayAnalyses.clear();

    for (int i = 0; i < vehicleRecords.length; i++) {
      _analyzeVehicleRecord(vehicleRecords[i], false, i);
    }

    if (includeReturn.value && returnRecords.isNotEmpty) {
      for (int i = 0; i < returnRecords.length; i++) {
        _analyzeVehicleRecord(returnRecords[i], true, i);
      }
    }

    isAnalyzing.value = false;
    Get.snackbar('Başarılı', 'Gecikme analizi tamamlandı!', 
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
  }

  void _analyzeVehicleRecord(VehicleRecord record, bool isReturn, int rowIndex) {
    List<StopDelay> stopDelays = [];
    int totalDelay = 0;

    if (record.arrivalTimes.isEmpty || stops.isEmpty) return;

    String thisRecordReferenceTime = _calculateReferenceStartTimeForRecord(rowIndex);
    String actualStartTime = record.arrivalTimes[0];
    int startDelay = _calculateTimeDifference(thisRecordReferenceTime, actualStartTime);

    stopDelays.add(StopDelay(
      stopName: "${stops[0].name} (Referans: $thisRecordReferenceTime)",
      delayMinutes: startDelay > 0 ? startDelay : 0,
      expectedTime: thisRecordReferenceTime,
      actualTime: actualStartTime,
    ));

    if (startDelay > 0) {
      totalDelay += startDelay;
    }

    for (int i = 1; i < record.arrivalTimes.length && i < stops.length; i++) {
      String previousStopTime = record.arrivalTimes[i - 1];
      String currentStopTime = record.arrivalTimes[i];
      int actualDuration = _calculateTimeDifference(previousStopTime, currentStopTime);

      int referenceDuration = stops[i].durationFromPrevious;
      int segmentDelay = actualDuration - referenceDuration;

      String expectedArrivalTime = _addMinutesToTime(previousStopTime, referenceDuration);

      stopDelays.add(StopDelay(
        stopName: stops[i].name + (i == stops.length - 1 ? " (Son Durak)" : ""),
        delayMinutes: segmentDelay > 0 ? segmentDelay : 0,
        expectedTime: expectedArrivalTime,
        actualTime: currentStopTime,
      ));

      if (segmentDelay > 0) {
        totalDelay += segmentDelay;
      }
    }

    delayAnalyses.add(DelayAnalysis(
      plateNumber: record.plateNumber,
      tripTime: thisRecordReferenceTime,
      totalDelayMinutes: totalDelay,
      stopDelays: stopDelays,
      isReturn: isReturn,
    ));
    delayAnalyses.refresh(); 
  }

  // ----------------------------------------------------
  // --- PDF GENERATION & SEARCH ---
  // ----------------------------------------------------

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  List<String> getUniqueVehiclePlates() {
    Set<String> plates = {};
    for (var record in vehicleRecords) {
      plates.add(record.plateNumber);
    }
    for (var record in returnRecords) {
      plates.add(record.plateNumber);
    }

    List<String> sortedPlates = plates.toList()..sort();

    if (searchQuery.isNotEmpty) {
      return sortedPlates.where((plate) =>
          plate.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return sortedPlates;
  }

  String _turkishToAscii(String text) {
      return text
          .replaceAll('ç', 'c').replaceAll('Ç', 'C')
          .replaceAll('ğ', 'g').replaceAll('Ğ', 'G')
          .replaceAll('ı', 'i').replaceAll('İ', 'I')
          .replaceAll('ö', 'o').replaceAll('Ö', 'O')
          .replaceAll('ş', 's').replaceAll('Ş', 'S')
          .replaceAll('ü', 'u').replaceAll('Ü', 'U');
  }

  Future<void> generatePDF(String plateNumber) async {
    var vehicleAnalyses = delayAnalyses.where((analysis) => analysis.plateNumber == plateNumber).toList();

    if (vehicleAnalyses.isEmpty) {
      Get.snackbar('Hata', 'Bu plaka için analiz bulunamadı!', 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
      return;
    }

    final pdf = pw.Document();
    
    // يجب تحميل خط يدعم اللغة التركية إذا كان التطبيق سيُطبع في تركيا
    // سنستخدم خط افتراضي لـ PDF (لا يدعم الأحرف التركية) ولهذا استخدمنا _turkishToAscii
    // يمكنك إضافة خط مخصص هنا: final font = await PdfGoogleFonts.notoSansTurkish();
    
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Minibus Gecikme Raporu - $plateNumber',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            ...vehicleAnalyses.map((analysis) {
              var delayedStops = analysis.stopDelays.where((stop) => stop.delayMinutes > 0).toList();
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Referans Kalkis: ${analysis.tripTime} ${analysis.isReturn ? "(Donus)" : "(Gidis)"}',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    if (analysis.totalDelayMinutes == 0)
                      pw.Text('✓ Arac gecikme yasamadi - Tum duraklar zamaninda',
                          style: pw.TextStyle(color: PdfColors.green, fontSize: 12))
                    else ...[
                      pw.Text('Toplam Gecikme: ${analysis.totalDelayMinutes} dakika',
                          style: pw.TextStyle(color: PdfColors.red, fontSize: 12)),
                      pw.SizedBox(height: 10),
                      if (delayedStops.isNotEmpty)
                        pw.Table.fromTextArray(
                          headers: ['Geciken Durak', 'Beklenen Varis', 'Gercek Varis', 'Gecikme (dk)'],
                          data: delayedStops.map((stopDelay) => [
                            _turkishToAscii(stopDelay.stopName),
                            stopDelay.expectedTime,
                            stopDelay.actualTime,
                            stopDelay.delayMinutes.toString(),
                          ]).toList(),
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                          cellStyle: pw.TextStyle(fontSize: 10),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.red100),
                          cellAlignment: pw.Alignment.centerLeft,
                        ),
                    ],
                    pw.SizedBox(height: 10),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
