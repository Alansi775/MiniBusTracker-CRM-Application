import 'package:firebase_database/firebase_database.dart';
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
import 'package:intl/intl.dart'; 
import 'package:firebase_core/firebase_core.dart';


//  تأكد من وجود هذين الملفين في مساراتهما
import '../data/models/user_model.dart'; 
import '../services/auth_service.dart';

// -------------------------------------------------------------------
// --- DATA MODELS (لتحليل التأخيرات) ---
// -------------------------------------------------------------------

class Stop {
  String name;
  int durationFromPrevious; 
  Stop({required this.name, required this.durationFromPrevious});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'durationFromPrevious': durationFromPrevious,
    };
  }

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      name: map['name']?.toString() ?? '',
      durationFromPrevious: (map['durationFromPrevious'] as num?)?.toInt() ?? 0,
    );
  }
}
// VehicleRecord (الهيكل الأفقي الذي تتوقعه دالة التحليل)
class VehicleRecord {
  String plateNumber;
  String date;
  List<String> arrivalTimes; // أوقات الوصول بالترتيب (HH:MM)
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
// --- INTERNAL MODEL FOR NEW EXCEL FORMAT (موديل داخلي للقراءة) ---
// -------------------------------------------------------------------

// موديل يمثل حدث وصول واحد للمركبة (من الملف العمودي الجديد)
class _StopEvent {
  final String plate;
  final String stopName;
  final DateTime arrivalTime; // تم التأكد من أنه ليس nullable
  _StopEvent({required this.plate, required this.stopName, required this.arrivalTime});
}

// -------------------------------------------------------------------
// --- ADMIN CONTROLLER (الدمج النهائي والمصحح) ---
// -------------------------------------------------------------------
const String RTDB_URL = 'https://minibuscrm-default-rtdb.europe-west1.firebasedatabase.app/';

class AdminController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: RTDB_URL,
  );



  final AuthService _authService = Get.find<AuthService>();


  StreamSubscription<DatabaseEvent>? _rtdbSubscription;
  String get _currentUserId => _authService.currentUser.value?.uid ?? '';
  DatabaseReference get _settingsRef => _rtdb.ref().child('user_settings').child(_currentUserId);  
  Timer? _debounceTimer; 
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
  final isLoading = false.obs; // ✅ تم إضافة حالة التحميل
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
    
    // 1. بدأ الاستماع لطلبات التسجيل المعلقة 
    _fetchPendingRequests();
    
    // 2. بدأ الاستماع لجميع المستخدمين وحالتهم الآنية
    _startUserAndLocationListeners();

    // 3. ربط بدء الاستماع RTDB بحالة المستخدم (التصحيح الأساسي هنا)
    ever(_authService.currentUser, (user) {
      if (user != null) {
        // ✅ 1. اضبط حالة التحميل على 'true' عند تسجيل الدخول أو التحديث
        isLoading.value = true;
        _startRtdbListener();
      } else {
        _rtdbSubscription?.cancel();
        stops.clear(); 
        isLoading.value = false; // إعادة ضبط عند تسجيل الخروج
      }
    });

    // 4. التشغيل الفوري إذا كان المستخدم مسجلاً بالفعل عند بدء التشغيل
    if (_authService.currentUser.value != null) {
        // ✅ 2. اضبط حالة التحميل على 'true' في onInit
        isLoading.value = true;
        _startRtdbListener();
    }
    
    // 5. تفعيل الحفظ التلقائي للمحطات بعد إضافة أو حذف محطة
    debounce(stops, (_) => _saveStops(), time: const Duration(milliseconds: 500));
    
    // 6. تفعيل الحفظ التلقائي للإعدادات عند تغيير المتغيرات الملاحظة
    //ever(referenceStartTime, (_) => _saveSettings());
    //ever(intervalBetweenBuses, (_) => _saveSettings());
  }

  void updateInterval(String value) {
        final int newInterval = int.tryParse(value) ?? 30;
        
        // 1. تحديث القيمة في المتغير المراقب على الفور
        intervalBetweenBuses.value = newInterval;

        // 2. إلغاء المؤقت الحالي إذا كان موجوداً (حتى لا يتم الحفظ الآن)
        if (_debounceTimer?.isActive ?? false) {
            _debounceTimer!.cancel();
        }

        // 3. بدء مؤقت جديد: الحفظ يتم فقط بعد التوقف عن الكتابة بـ 500ms
        _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
            // استدعاء دالة الحفظ العامة (saveSettings)
            saveSettings(); 
        });
    }

  // ----------------------------------------------------
  // --- REALTIME DB PERSISTENCE LOGIC (منطق الحفظ والتحميل) ---
  // ----------------------------------------------------


  // ✅ 1. بدء الاستماع لتحميل البيانات في الوقت الفعلي (التصحيح هنا)
  void _startRtdbListener() {
    if (_currentUserId.isEmpty) return;

    // ✅ تأكد من أن حالة التحميل 'true' قبل بدء الاستماع
    if (!isLoading.value) {
        isLoading.value = true;
    }

    _rtdbSubscription?.cancel();
    
    _rtdbSubscription = _settingsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        stops.clear();
        // مسح المتحكمات النصية في حالة عدم وجود بيانات
        startTimeController.text = "06:30";
        intervalController.text = "30";
      } else {
        // 1. تحميل الإعدادات (وقت البدء والفاصل)
        final settings = data['settings'] as Map<dynamic, dynamic>?;
        if (settings != null) {
          if (settings.containsKey('referenceStartTime')) {
            referenceStartTime.value = settings['referenceStartTime']?.toString() ?? "06:30";
          }
          if (settings.containsKey('intervalBetweenBuses')) {
            intervalBetweenBuses.value = (settings['intervalBetweenBuses'] as num?)?.toInt() ?? 30;
          }
        }
        // ✅ تحديث المتحكمات النصية بعد التحميل
        startTimeController.text = referenceStartTime.value;
        intervalController.text = intervalBetweenBuses.value.toString();


        // 2. تحميل قائمة المحطات (التصحيح الأساسي هنا لمعالجة الخرائط والقوائم)
        final stopsListRaw = data['stops'];
        List<Stop> loadedStops = [];

        if (stopsListRaw is List) {
            // حالة RTDB أعادت قائمة صحيحة 
            loadedStops = stopsListRaw
                .where((item) => item != null)
                .map((map) => Stop.fromMap(Map<String, dynamic>.from(map)))
                .toList();
        } else if (stopsListRaw is Map) {
            // حالة RTDB أعادت خريطة بمفاتيح رقمية (السيناريو المتوقع في الويب)
            
            // تحويل المفاتيح إلى أرقام، فرزها، ثم قراءة القيمة بترتيب صحيح
            List<int> sortedKeys = stopsListRaw.keys
                .map((k) => int.tryParse(k.toString()) ?? -1)
                .where((k) => k != -1) // استبعاد المفاتيح غير الصالحة
                .toList()..sort();
            
            loadedStops = sortedKeys
                .map((k) => Stop.fromMap(Map<String, dynamic>.from(stopsListRaw[k.toString()] as Map<dynamic, dynamic>)))
                .toList();
        }

        if (loadedStops.isNotEmpty) {
          stops.value = loadedStops;
        } else {
           stops.clear();
        }
      }

      // ✅ 3. نهاية حالة التحميل بعد معالجة البيانات بنجاح
      isLoading.value = false;

    }, onError: (error) {
      // ✅ 4. نهاية حالة التحميل في حالة الخطأ
      isLoading.value = false; 
      Get.snackbar('Hata', 'RTDB verileri yüklenemedi: $error', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    });
  }

  // ✅ 2. دالة لحفظ قائمة المحطات في RTDB
  Future<void> _saveStops() async {
    if (_currentUserId.isEmpty) return;
    
    final stopsData = stops.map((s) => s.toMap()).toList();
    
    try {
      // تحديث فقط عقدة 'stops' تحت المستخدم
      await _settingsRef.update({
        'stops': stopsData,
      });
    } catch (e) {
      _showModernToast('Hata', 'Duraklar kaydedilemedi: $e', isSuccess: false);
    }
  }

  // ✅ 3. دالة لحفظ الإعدادات الزمنية (وقت البدء والفاصل) في RTDB
  Future<void> saveSettings() async { // 👈 تم تغيير الاسم
  if (_currentUserId.isEmpty) return;

  try {
    // بناء الخريطة المراد حفظها
    final settingsMap = {
      'referenceStartTime': referenceStartTime.value,
      'intervalBetweenBuses': intervalBetweenBuses.value,
    };
    
    // الحفظ في Firebase
    await _settingsRef.update({
      'settings': settingsMap,
    });
    
    // ملاحظة: لا نحتاج لـ Get.snackbar هنا إلا في حالة الخطأ
    
  } catch (e) {
    Get.snackbar('Hata', 'Ayarlar kaydedilemedi: $e', 
      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
  }
}
  
  // دالة لبدء الاستماع لكل المستخدمين والمواقع (تم نقلها داخل الفئة)
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
      
      _showModernToast(
        'Başarılı',
        '${user.name} sistemden kalıcı olarak silindi.',
        isSuccess: true
      );

    } catch (e) {
    _showModernToast(
      'Hata',
      'Kullanıcı silinemedi: $e',
      isSuccess: false
      );
    }
  }


  void _showModernToast(String title, String message, {required bool isSuccess}) {
    final Color accentColor = isSuccess ? Colors.green.shade600 : Colors.red.shade600;
    final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
    
    final Widget toastContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Material(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(14), 
          
          constraints: const BoxConstraints(
            maxWidth: 340,
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
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 12),
              
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.close, color: Colors.black26, size: 16),
              ),
            ],
          ),
        ),
      ),
    );

    Get.snackbar(
      '', '', 
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 1500),
      isDismissible: true,
      
      titleText: const SizedBox.shrink(),
      messageText: Center(child: toastContent), 
      
      backgroundColor: Colors.transparent, 
      boxShadows: const [],
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
      barBlur: 0,
      overlayBlur: 0,

      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 300), 
      
      icon: const SizedBox.shrink(),
      shouldIconPulse: false,
      mainButton: null,
    );
  }

  void viewUserOnMap(String userId, double? lat, double? lng) async {
    if (lat == null || lng == null) {
      Get.snackbar('Hata', 'Kullanıcının canlı konumu mevcut değil.', 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange);
      return;
    }
    
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'; 
    
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
      _showModernToast('Başarılı', 'Yeni durak eklendi.', isSuccess: true);
    }
  }

  void removeStop(int index) {
    stops.removeAt(index);
  }

  // ----------------------------------------------------
  // --- FILE UPLOAD (تحميل ملف Excel) - NEW LOGIC ---
  // ----------------------------------------------------
  
  Future<void> uploadExcelFile(bool isReturnFile) async {
    isLoading.value = true;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null || result.files.single.bytes == null) {
      isLoading.value = false;
      return;
    }

    try {
      var bytes = result.files.single.bytes!;
      var excel = Excel.decodeBytes(bytes);
      
      // Map لتجميع الأحداث في رحلات (المفتاح: "Plate_Date")
      Map<String, List<_StopEvent>> groupedTrips = {};

      // 1. إيجاد الورقة الصحيحة وقراءة العناوين
      var tableKey = excel.tables.keys.first;
      var sheet = excel.tables[tableKey]!;
      
      if (sheet.maxRows < 2) {
          throw Exception('Excel dosyası veri satırı içermiyor.');
      }

      // قراءة العناوين من الصف 0
      final List<String> headers = sheet.rows[0].map((cell) => cell?.value?.toString().trim() ?? '').toList();

      // تحديد مؤشرات الأعمدة للهيكل العمودي الجديد
      final int vehicleIndex = headers.indexOf('Araç');
      final int stopIndex = headers.indexOf('Bölge');
      final int dateIndex = headers.indexOf('Başlangıç tarihi'); 
      final int timeIndex = headers.indexOf('Başlangıç saati');

      // 2. التحقق من صحة العناوين
      if (vehicleIndex == -1 || stopIndex == -1 || dateIndex == -1 || timeIndex == -1) {
          throw Exception('Excel sütunları hatalı. Gerekli sütunlar: "Araç", "Bölge", "Başlangıç tarihi", "Başlangıç saati".');
      }

      // تنسيق التاريخ والوقت للدمج
      final DateFormat inputFormat = DateFormat('dd.MM.yyyy HH:mm:ss'); 

      // 3. المرور على الصفوف وتحويل/تجميع الأحداث
      for (int row = 1; row < sheet.maxRows; row++) {
        var cells = sheet.rows[row];
        if (cells.length < headers.length) continue; 

        // استخلاص البيانات الخام
        String plate = cells[vehicleIndex]?.value?.toString().trim().replaceAll(' ', '') ?? '';
        String stopName = cells[stopIndex]?.value?.toString().trim() ?? '';
        String datePart = cells[dateIndex]?.value?.toString().trim() ?? '';
        String timePart = cells[timeIndex]?.value?.toString().trim() ?? '';

        if (plate.isEmpty || stopName.isEmpty || datePart.isEmpty || timePart.isEmpty) continue;

        // دمج التاريخ والوقت إلى DateTime
        DateTime? arrivalTime;
        try {
            String combinedDateTime = '$datePart $timePart';
            // إضافة الثواني لضمان التنسيق (إذا كانت مفقودة)
            if (timePart.split(':').length == 2) {
                combinedDateTime += ':00'; 
            }
            // قراءة التاريخ
            arrivalTime = inputFormat.parse(combinedDateTime);
        } catch (e) {
            // تجاهل السجلات غير القابلة للقراءة
            continue; 
        }
        
        final event = _StopEvent(
            plate: plate, 
            stopName: stopName, 
            arrivalTime: arrivalTime!, 
        );

        // التجميع بناءً على اللوحة والتاريخ لتمثيل "رحلة" واحدة في يوم معين
        String key = '${plate}_$datePart';
        if (!groupedTrips.containsKey(key)) {
            groupedTrips[key] = [];
        }
        groupedTrips[key]!.add(event);
      }
      
      // 4. تحويل الأحداث المجمعة إلى هيكل VehicleRecord (Wide Format)
      List<VehicleRecord> finalRecords = [];
      
      // المرور على الرحلات المجمعة
      groupedTrips.forEach((key, events) {
          // ترتيب الأحداث حسب وقت الوصول لضمان الترتيب الصحيح للمحطات في الرحلة
          events.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
          
          String date = DateFormat('dd.MM.yyyy').format(events.first.arrivalTime);
          
          // إنشاء قائمة بأوقات الوصول (HH:MM) التي تتوقعها دالة التحليل القديمة
          List<String> arrivalTimes = events.map((e) => DateFormat('HH:mm').format(e.arrivalTime)).toList();
          
          finalRecords.add(VehicleRecord(
              plateNumber: events.first.plate,
              date: date,
              arrivalTimes: arrivalTimes,
          ));
      });
      
      // ترتيب الرحلات حسب وقت بدء أول وصول للحفاظ على منطق الـ rowIndex في دالة التحليل
      finalRecords.sort((a, b) {
          // قارن بين أول وقت وصول في كل رحلة
          String timeA = a.arrivalTimes.first;
          String timeB = b.arrivalTimes.first;
          return timeA.compareTo(timeB);
      });
      
      // 5. تحديث متغيرات الكنترولر
      if (isReturnFile) {
        returnRecords.value = finalRecords;
      } else {
        vehicleRecords.value = finalRecords;
      }

      Get.snackbar('Başarılı', 'Excel dosyası başarıyla yüklendi (${finalRecords.length} sefer bulundu).', 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);

    } catch (e) {
      Get.snackbar('Hata', 'Dosya okuma/dönüştürme hatası: ${e.toString()}', 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
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

    // 1. حساب وقت الانطلاق المرجعي (Expected Start Time)
    String thisRecordReferenceTime = _calculateReferenceStartTimeForRecord(rowIndex);
    String actualStartTime = record.arrivalTimes[0];
    int startDelay = _calculateTimeDifference(thisRecordReferenceTime, actualStartTime);

    // إضافة أول نقطة (نقطة الانطلاق)
    stopDelays.add(StopDelay(
      stopName: "${stops[0].name} (Referans: $thisRecordReferenceTime)",
      delayMinutes: startDelay > 0 ? startDelay : 0,
      expectedTime: thisRecordReferenceTime,
      actualTime: actualStartTime,
    ));

    if (startDelay > 0) {
      totalDelay += startDelay;
    }

    // 2. حساب التأخير بين المحطات
    for (int i = 1; i < record.arrivalTimes.length && i < stops.length; i++) {
      String previousStopTime = record.arrivalTimes[i - 1];
      String currentStopTime = record.arrivalTimes[i];
      
      // المدة الفعلية المستغرقة بين المحطتين
      int actualDuration = _calculateTimeDifference(previousStopTime, currentStopTime);

      // المدة المرجعية المتوقعة بين المحطتين
      int referenceDuration = stops[i].durationFromPrevious;
      
      // التأخير التراكمي في هذا المقطع (segment delay)
      int segmentDelay = actualDuration - referenceDuration;

      // الوقت المتوقع للوصول لهذه المحطة بناءً على وصول المحطة السابقة + المدة المرجعية
      String expectedArrivalTime = _addMinutesToTime(previousStopTime, referenceDuration);

      stopDelays.add(StopDelay(
        stopName: stops[i].name + (i == stops.length - 1 ? " (Son Durak)" : ""),
        delayMinutes: segmentDelay > 0 ? segmentDelay : 0, // فقط التأخير الموجب
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