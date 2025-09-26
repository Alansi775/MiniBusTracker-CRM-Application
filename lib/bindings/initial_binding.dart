import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart'; 
import '../controllers/bus_controller.dart'; 

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // 1. SERVICES
    Get.put<AuthService>(AuthService(), permanent: true); 

    // 2. CONTROLLERS الأساسية (Permanent)
    Get.put<AuthController>(AuthController(), permanent: true); 
    
    // 3. CONTROLLERS الخاصة بالميزات (LazyPut with fenix)
    // fenix: true يسمح بإعادة إنشاء الـ Controller إذا تم التخلص منه (مثل عند التنقل بين الصفحات)
    
    // (2) AdminController
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true); 
    
    // (3) BusController
    Get.lazyPut<BusController>(() => BusController(), fenix: true); 
  }
}