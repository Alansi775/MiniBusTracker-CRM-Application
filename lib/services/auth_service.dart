// lib/services/auth_service.dart (الكود النهائي والصحيح مع خصائص BusController)

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../data/models/user_model.dart'; // يتطلب ملف user_model.dart ليكون صحيحًا
import 'package:flutter/material.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  StreamSubscription<User?>? _authStateSubscription;

  // ==================================================
  // === 🚨 الخصائص المطلوبة من BusController (حل الأخطاء) 🚨 ===
  // ==================================================
  
  // 1. خاصية isAuthenticated
  final RxBool isAuthenticated = false.obs; 

  // 2. خاصية currentUserId
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // ==================================================
  // === LIFECYCLE ===
  // ==================================================

  @override
  void onInit() {
    super.onInit();
    debugPrint('AuthService: Starting Firebase Auth state listener.');
    _startListening();
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }

  // ----------------------------------------------------
  // دوال التحكم في Listener
  // ----------------------------------------------------

  void _startListening() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _auth.authStateChanges().listen(_firebaseUserChanged);
  }
  
  void pauseListening() {
    _authStateSubscription?.pause();
    debugPrint('AuthService: Listener PAUSED.');
  }

  Future<void> resumeListening() async {
    _authStateSubscription?.resume();
    debugPrint('AuthService: Listener RESUMED.');
    await _firebaseUserChanged(_auth.currentUser); 
  }


  // ----------------------------------------------------
  // تدفق المصادقة الأساسي
  // ----------------------------------------------------

  Future<void> _firebaseUserChanged(User? firebaseUser) async {
    if (_authStateSubscription?.isPaused ?? false) {
      debugPrint('AuthService: Listener is currently paused. Skipping redirect.');
      return;
    }

    if (firebaseUser != null) {
      isAuthenticated.value = true; // 🚨 تحديث عند تسجيل الدخول
      debugPrint('AuthService: User logged in (UID: ${firebaseUser.uid}). Fetching Firestore data...');
      await fetchUserData(firebaseUser.uid);
    } else {
      isAuthenticated.value = false; // 🚨 تحديث عند تسجيل الخروج
      debugPrint('AuthService: User logged out/null. Redirecting to /login.');
      currentUser.value = null;
      Get.offAllNamed('/login');
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        UserModel user = UserModel.fromMap(doc.data()!);
        currentUser.value = user;
        _redirectBasedOnRole(user);
      } else {
        debugPrint('AuthService: CRITICAL: Firestore data MISSING or NULL for UID: $uid. Signing out.');
        await _auth.signOut();
        Get.snackbar('Hata', 'Kullanıcı verisi eksik. Lütfen yöneticiye başvurun.',
                     snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      }
    } catch (e) {
      debugPrint('AuthService: Error fetching user data: $e. Signing out.');
      await _auth.signOut();
    }
  }

  void _redirectBasedOnRole(UserModel user) {
    debugPrint('AuthService: Redirecting user role: ${user.role.toString().split('.').last}');

    if (user.isBlocked) {
      Get.snackbar('Hata', 'Hesabınız bloke edilmiştir.', snackPosition: SnackPosition.BOTTOM);
      _auth.signOut();
      return;
    }

    if (!user.isApproved) {
        debugPrint('AuthService: -> Redirecting to Login/Pending status.');
        Get.snackbar('Onay Bekleniyor', 'Hesabınız henüz yönetici tarafından onaylanmadı.',
                     snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.withOpacity(0.9), colorText: Colors.white);
        _auth.signOut(); 
        return;
    }
    
    if (user.mustChangePassword) {
      debugPrint('AuthService: -> Redirecting to Change Password.');
      Get.offAllNamed('/change_password');
      return;
    }
    
    if (user.role == UserRole.superAdmin || user.role == UserRole.admin) {
      debugPrint('AuthService: -> Redirecting to Admin Delay Analysis.');
      Get.offAllNamed('/admin/delay_analysis'); 
    } else if (user.role == UserRole.user) {
      debugPrint('AuthService: -> Redirecting to User Home.');
      Get.offAllNamed('/user_home');
    } else {
       _auth.signOut();
    }
  }

  // ----------------------------------------------------
  // دالة التسجيل (Sign Up)
  // ----------------------------------------------------
  Future<bool> registerUser({
    required String email, 
    required String password,
    required String name,
    required String surname,
    required String username,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final newUid = userCredential.user!.uid;

      await _auth.signOut(); 
      
      final newUser = UserModel(
        uid: newUid,
        email: email,
        name: name,
        surname: surname,
        username: username, 
        role: UserRole.pending, 
        isBlocked: false,
        mustChangePassword: false, 
        isApproved: false, 
      );
      
      await _db.collection('users').doc(newUid).set(newUser.toMap());
      
      debugPrint('AuthService: New pending user registered: $email');
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt sırasında bir hata oluştu.';
      if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten sistemde kayıtlıdır.';
      } else if (e.code == 'weak-password') {
        message = 'Şifre çok zayıف.';
      }
      Get.snackbar('Kayıt Hatası', message, snackPosition: SnackPosition.BOTTOM, 
                   backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      return false;
    }
  }

  // ----------------------------------------------------
  // دوال تسجيل الدخول والخروج والتحديث
  // ----------------------------------------------------

  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
       String message = 'Bir hata oluştu.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Kullanıcı adı veya şifre yanlış.';
      } else if (e.code == 'network-request-failed') {
        message = 'İnternet bağlantınızı kontrol edin.';
      }
      Get.snackbar('Giriş Hatası', message, snackPosition: SnackPosition.BOTTOM, 
                   backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      return false;
    }
  }

  Future<void> signOut() async {
    debugPrint('AuthService: Signing out user.');
    await _auth.signOut();
  }

  Future<bool> updateUserInfo({String? newName, String? newSurname, String? newPassword}) async {
    if (currentUser.value == null) return false;
    
    final user = _auth.currentUser;
    if (user == null) return false;
    
    bool updateSuccess = true;
    
    try {
      if (newPassword != null && newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
        debugPrint('AuthService: Password updated in Auth.');
      }
      
      Map<String, dynamic> updates = {};
      if (newName != null) updates['name'] = newName;
      if (newSurname != null) updates['surname'] = newSurname;
      
      if (newPassword != null && currentUser.value!.mustChangePassword) {
        updates['mustChangePassword'] = false;
        debugPrint('AuthService: mustChangePassword flag set to false.');
      }
      
      if (updates.isNotEmpty) {
        await _db.collection('users').doc(user.uid).update(updates);
        await fetchUserData(user.uid); 
        debugPrint('AuthService: Firestore data updated.');
      }
      
      Get.snackbar('Başarılı', 'Bilgileriniz güncellendi.', snackPosition: SnackPosition.BOTTOM, 
                   backgroundColor: Colors.green, colorText: Colors.white);
                   
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Update failed: ${e.code} - ${e.message}');
      Get.snackbar('Hata', 'Güncelleme başarısız: Lütfen tekrar giriş yapıp tekrar deneyين.', 
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      updateSuccess = false;
    }
    
    return updateSuccess;
  }
}