import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:google_fonts/google_fonts.dart'; 
import 'bindings/initial_binding.dart';
import 'controllers/auth_controller.dart'; // لربط SplashView بالـ AuthController
import 'views/auth/sign_in_view.dart';
import 'views/auth/change_password_view.dart';
import 'views/admin/admin_dashboard_view.dart';
import 'views/admin/admin_home_view.dart'; 
import 'views/user/user_home_view.dart'; 
import 'views/auth/sign_up_view.dart'; 
import 'views/admin/pending_requests_view.dart'; 
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Run the App
  runApp(const MyApp());
}

// 🛑 NEW WIDGET: Splash View for initial redirection
class SplashView extends GetView<AuthController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // هذا الويدجت يجبر GetX على بناء AuthController وبدء عملية التحقق والتحويل
    return const Scaffold(
      backgroundColor: MyApp.primaryBrandColor,
      body: Center(
        child: CircularProgressIndicator(color: MyApp.accentBrandColor),
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // تعريف الألوان الموحدة
  static const Color primaryBrandColor = Colors.black87; // الأسود الداكن
  static const Color accentBrandColor = Color(0xFFFFC107); // الذهبي
  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( 
      title: 'Minibüs CRM',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        primaryColor: primaryBrandColor,
        scaffoldBackgroundColor: const Color(0xFFF0F0F0), 
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false, 

        fontFamily: GoogleFonts.playfairDisplay().fontFamily,
        
        iconTheme: const IconThemeData(
          color: primaryBrandColor, 
        ),
        
        appBarTheme: AppBarTheme(
          elevation: 0, 
          centerTitle: true,
          backgroundColor: Colors.white,
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: primaryBrandColor, 
            fontWeight: FontWeight.w900, 
            fontSize: 20
          ),
          iconTheme: const IconThemeData(color: primaryBrandColor),
        ),
        
        colorScheme: const ColorScheme.light(
          primary: primaryBrandColor,
          secondary: accentBrandColor,
          onSurface: primaryBrandColor, 
        ),
      ),
      
      // 🛑 التعديل الرئيسي: استخدام initialRoute بدلاً من home
      initialRoute: '/splash',
      
      // Define all routes
      getPages: [
        // 1. مسار الـ Splash الجديد
        GetPage(
          name: '/splash', 
          page: () => const SplashView(), 
          binding: BindingsBuilder(() {
            // ضمان أن AuthController متاح فورًا لبدء التحقق
            Get.find<AuthController>();
          }),
        ),
        
        GetPage(name: '/login', page: () => const SignInView()),
        GetPage(name: '/signup', page: () => const SignUpView()), 
        GetPage(name: '/change_password', page: () => const ChangePasswordView()), 
        GetPage(name: '/pending_requests', page: () => const PendingRequestsView()), 

        GetPage(
          name: '/admin_dashboard',
          page: () => AdminDashboardView(),
          transition: Transition.fade,
          transitionDuration: const Duration(milliseconds: 20),
          ),
        
        GetPage(
          name: '/admin/delay_analysis',
          page: () => const AdminHomeView(),
          transition: Transition.fade,
          transitionDuration: const Duration(milliseconds: 20),
          ), 
        
        GetPage(name: '/user_home', page: () => const UserHomeView()), 
      ],
      
      // home: const Scaffold( body: Center(child: CircularProgressIndicator()), ),
    );
  }
}