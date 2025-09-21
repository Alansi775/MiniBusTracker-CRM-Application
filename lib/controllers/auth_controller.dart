// lib/controllers/auth_controller.dart (التصحيح الشامل)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_string/random_string.dart'; // لتوليد أجزاء عشوائية
import '../data/models/user_model.dart';
import '../services/auth_service.dart'; // يجب التأكد من وجوده

class AuthController extends GetxController {
  // SERVICES & UTILITIES
  final FirebaseAuth _auth = FirebaseAuth.instance; // 🚨 تم استعادة هذا
  final FirebaseFirestore _db = FirebaseFirestore.instance; // 🚨 تم استعادة هذا
  final AuthService _authService = Get.find<AuthService>();

  AuthService get authService => _authService; // لسهولة الوصول في الواجهات

  // --- CONTROLLERS ---
  
  // 1. Sign In Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // 2. Sign Up Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  // ❌ تم حذف signupEmailController لأنه سيتم توليده
  final TextEditingController signupPasswordController = TextEditingController();
  final TextEditingController signupConfirmPasswordController = TextEditingController();

  // 3. Change Password Controllers
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // --- STATE VARIABLES ---
  
  final isLoading = false.obs; // 🚨 تم استعادة هذا
  
  // 1. Sign In / General
  final isPasswordVisible = false.obs;
  
  // 2. Sign Up (Generated Username)
  final RxString generatedUsername = ''.obs; // 🚨 لتوليد وعرض اسم المستخدم

  // 3. Change Password
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;


  @override
  void onInit() {
    super.onInit();
    // الاستماع للتغييرات لتوليد اسم المستخدم تلقائيًا
    nameController.addListener(_generateUsernameOnInput);
    surnameController.addListener(_generateUsernameOnInput);
  }
  
  // --- Visibility Toggles ---
  
  void togglePasswordVisibility() => isPasswordVisible.toggle(); // لصفحة Sign In
  void toggleNewPasswordVisibility() => isNewPasswordVisible.toggle(); // لصفحة Change Password
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle(); // لصفحة Change Password

  // ----------------------------------------------------
  // --- USERNAME GENERATION LOGIC ---
  // ----------------------------------------------------
  
  // دالة توليد اسم المستخدم وعرضه بشكل مستمر
  void _generateUsernameOnInput() {
    final name = nameController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final surname = surnameController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

    if (name.isNotEmpty || surname.isNotEmpty) {
      // المنطق: الاسم.اللقب@minibus.com (أو فقط اللقب إذا لم يوجد اسم)
      String base = name.isNotEmpty ? '$name.$surname' : surname;
      if (base.endsWith('.')) base = base.substring(0, base.length - 1);
      
      generatedUsername.value = '${base.isEmpty ? 'kullanici' : base}@minibus.com';
    } else {
      generatedUsername.value = '';
    }
  }

  // دالة توليد اسم مستخدم فريد (للتسجيل)
  Future<String> _generateUniqueFinalUsername(String name, String surname) async {
    final namePart = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final surnamePart = surname.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    String baseUsername = namePart.isNotEmpty ? '$namePart.$surnamePart' : surnamePart;
    if (baseUsername.isEmpty) baseUsername = 'user';
    if (baseUsername.endsWith('.')) baseUsername = baseUsername.substring(0, baseUsername.length - 1);

    String username = baseUsername;
    int counter = 0;
    
    // حلقة لضمان تفرد اسم المستخدم
    while (true) {
      final finalUsername = '$username@minibus.com';
      
      // البحث في مجموعة المستخدمين
      final querySnapshot = await _db.collection('users')
          .where('username', isEqualTo: finalUsername)
          .limit(1).get();
          
      if (querySnapshot.docs.isEmpty) {
        return finalUsername; // تم العثور على اسم فريد
      }
      
      // إذا كان موجوداً، أضف عداداً عشوائياً (رقمين عشوائيين)
      counter++;
      final randomSuffix = randomNumeric(3); // 3 أرقام
      username = '$baseUsername$randomSuffix';
    }
  }


  // ----------------------------------------------------
  // --- SIGN UP LOGIC (KAYIT OL) ---
  // ----------------------------------------------------
  
  Future<void> signUp() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final password = signupPasswordController.text;
    final confirmPassword = signupConfirmPasswordController.text;

    if (name.isEmpty || surname.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar('Hata', 'Lütfen tüm alanları doldurun.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar('Hata', 'Şifreler eşleşmiyor.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }
    if (password.length < 6) {
      Get.snackbar('Hata', 'Şifre en az 6 karakter olmalıdır.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }

    isLoading.value = true;
    try {
      // 1. توليد اسم المستخدم الفريد
      final finalUsername = await _generateUniqueFinalUsername(name, surname);
      
      // 2. التسجيل في AuthService باستخدام finalUsername كـ Email
      final success = await _authService.registerUser(
        email: finalUsername, // استخدام اليوزرنيم كإيميل للتسجيل في Firebase
        password: password,
        name: name,
        surname: surname,
        username: finalUsername, // حفظ اليوزرنيم في حقل منفصل
      );

      isLoading.value = false;
      
      if (success) {
        Get.snackbar(
          'Başarılı', 
          'Kaydınız alındı. Kullanıcı adınız: $finalUsername', 
          snackPosition: SnackPosition.TOP, 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          colorText: Colors.white
        );
        
        Get.offAllNamed('/login'); // العودة إلى شاشة تسجيل الدخول
      } 
      // رسائل الخطأ يتم التعامل معها في AuthService

    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Hata', 'Beklenmedik bir hata oluştu: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
    }
  }


  // ----------------------------------------------------
  // --- SIGN IN LOGIC (GİRİŞ YAP) ---
  // ----------------------------------------------------
  
  Future<void> signIn() async { // 🚨 تم استعادة هذا
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Hata', 'Lütfen tüm alanları doldurun.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return;
    }

    isLoading.value = true;
    // نستخدم الـ emailController لحقل اسم المستخدم / الإيميل
    final success = await _authService.signIn(emailController.text.trim(), passwordController.text.trim());
    isLoading.value = false;
  }
  
  // ----------------------------------------------------
  // --- PASSWORD CHANGE LOGIC ---
  // ----------------------------------------------------
  
  // لتغيير كلمة المرور الإجباري (من AuthService)
  Future<void> mandatoryPasswordChange() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();
    // ... (منطق التحقق)
    
    if (newPass.isEmpty || confirmPass.isEmpty || newPass != confirmPass || newPass.length < 6) {
       Get.snackbar('Hata', 'Lütfen şifreleri kontrol edin (min 6 karakter).', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
       return;
    }
    
    isLoading.value = true;
    final success = await _authService.updateUserInfo(newPassword: newPass); 
    isLoading.value = false;

    if (success) {
      Get.snackbar('Başarılı', 'Şifre başarıyla güncellendi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
      // التوجيه يتم بواسطة AuthService listener
    }
  }

  // لتغيير كلمة المرور العادي (من Admin Dashboard)
  Future<void> updatePassword() async { // 🚨 تم استعادة هذا
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty || newPass != confirmPass || newPass.length < 6) {
       Get.snackbar('Hata', 'Lütfen şifreleri kontrol edin (min 6 karakter).', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
       return;
    }

    isLoading.value = true;
    final success = await _authService.updateUserInfo(newPassword: newPass); 
    isLoading.value = false;

    if (success) {
      newPasswordController.clear();
      confirmPasswordController.clear();
      Get.snackbar('Başarılı', 'Şifre başarıyla güncellendi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
      Get.back(); // يرجع للشاشة السابقة
    }
  }

  // ----------------------------------------------------
  // --- LOGOUT LOGIC ---
  // ----------------------------------------------------
  
  void signOut() { // 🚨 تم استعادة هذا
    _authService.signOut();
  }

  @override
  void onClose() {
    nameController.removeListener(_generateUsernameOnInput);
    surnameController.removeListener(_generateUsernameOnInput);

    // تفريغ كل الـ controllers
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    
    super.onClose();
  }
}