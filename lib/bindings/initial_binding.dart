// lib/bindings/initial_binding.dart (النهائي)

import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart'; 
import '../controllers/bus_controller.dart'; // 🚨 (1) إضافة الكنترولر الجديد

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // 1. SERVICES
    // يجب أن يكون AuthService دائم (permanent) لأنه القلب النابض لإدارة حالة المستخدم
    Get.put<AuthService>(AuthService(), permanent: true); 

    // 2. CONTROLLERS الأساسية (التي تعتمد على AuthService)
    // AuthController يجب أن يكون دائم (permanent) للتعامل مع تسجيل الدخول والخروج والتحويل
    Get.put<AuthController>(AuthController(), permanent: true); 
    
    // 3. CONTROLLERS الخاصة بالميزات (Get.lazyPut هو الأفضل هنا)
    // سنستخدم Get.lazyPut لـ AdminController و BusController لتوفير الذاكرة، 
    // ولن يتم إنشاؤهما إلا عند الحاجة الفعلية.
    
    // (2) AdminController
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true); 
    
    // (3) BusController
    Get.lazyPut<BusController>(() => BusController(), fenix: true); // 🚨 (2) إضافة BusController بـ lazyPut
  }
}