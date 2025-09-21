// lib/controllers/bus_controller.dart (للتتبع اللحظي)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // 🚨 تم إضافتها الآن
import '../services/auth_service.dart';

class BusController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>(); 
  
  final RxBool isTracking = false.obs;
  final RxMap<String, dynamic> currentLocation = <String, dynamic>{}.obs; 
  Timer? _locationUpdateTimer;
  final int updateIntervalSeconds = 10; 
  
  // ----------------------------------------------------
  // --- CORE TRACKING LOGIC (تم تفعيل الكود الجاهز) ---
  // ----------------------------------------------------

  Future<void> startTracking() async {
    if (isTracking.value) return; 

    // 1. التحقق من صلاحيات الموقع (منطق Geolocator)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Hata', 'Lütfen konum hizmetlerini açın.', duration: const Duration(seconds: 5));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Hata', 'Konum izni olmadan takip yapılamaz.', duration: const Duration(seconds: 5));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Hata', 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.', duration: const Duration(seconds: 5));
      return;
    }
    
    isTracking.value = true;
    Get.snackbar('Başladı', 'Konum takibi başlatıldı.', duration: const Duration(seconds: 3), backgroundColor: Colors.green);

    // 2. بدأ المؤقت لإرسال الموقع بشكل دوري
    _locationUpdateTimer = Timer.periodic(Duration(seconds: updateIntervalSeconds), (timer) {
      _sendLocationToFirestore();
    });

    _sendLocationToFirestore();
  }

  void stopTracking() {
    if (!isTracking.value) return;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    isTracking.value = false;
    currentLocation.value = {}; 
    
    Get.snackbar('Durduruldu', 'Konum takibi durduruldu.', duration: const Duration(seconds: 3), backgroundColor: Colors.red);
  }

  Future<void> _sendLocationToFirestore() async {
    if (!_authService.isAuthenticated.value) {
      stopTracking();
      return;
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _authService.currentUserId,
        'isTracking': true,
      };

      currentLocation.value = locationData;
      
      await _db.collection('bus_locations').doc(_authService.currentUserId).set(locationData);

    } catch (e) {
      debugPrint('Error getting or sending location: $e');
    }
  }

  @override
  void onClose() {
    _locationUpdateTimer?.cancel();
    super.onClose();
  }
}