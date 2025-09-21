import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:google_fonts/google_fonts.dart'; 
import 'bindings/initial_binding.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 🚨 تعريف الألوان الموحدة
  static const Color primaryBrandColor = Colors.black87; // الأسود الداكن
  static const Color accentBrandColor = Color(0xFFFFC107); // الذهبي
  
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( 
      title: 'Minibüs CRM',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      
      theme: ThemeData(
        // الألوان والخلفية الموحدة
        primarySwatch: Colors.blue, 
        primaryColor: primaryBrandColor,
        scaffoldBackgroundColor: const Color(0xFFF0F0F0), // خلفية فاتحة موحدة
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false, 

        // 🚨 1. تطبيق خط Playfair Display كخط افتراضي للنصوص
        fontFamily: GoogleFonts.playfairDisplay().fontFamily,
        
        // 🚨 2. نحدد لون الأيقونات فقط
        iconTheme: const IconThemeData(
          color: primaryBrandColor, 
          // تم حذف: fontFamily: 'MaterialIcons',
        ),
        
        // 🚨 3. توحيد ثيم الـ AppBar
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
        
        // 4. ضبط لون التمييز والظل
        colorScheme: const ColorScheme.light(
          primary: primaryBrandColor,
          secondary: accentBrandColor,
          onSurface: primaryBrandColor, 
        ),
      ),
      
      // Define all routes
      getPages: [
        GetPage(name: '/login', page: () => const SignInView()),
        GetPage(name: '/signup', page: () => const SignUpView()), 
        GetPage(name: '/change_password', page: () => const ChangePasswordView()), 
        GetPage(name: '/pending_requests', page: () => const PendingRequestsView()), 

        GetPage(
          name: '/admin_dashboard',
          page: () => const AdminDashboardView(),
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
      
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}