import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    // ใช้ 10.0.3.2 สำหรับ Genymotion (หรือ 10.0.2.2 สำหรับ Android Studio Emulator)
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.3.2:8000';
    return 'http://127.0.0.1:8000';
  }
}

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const result = '/result';
  static const inspection = '/inspection';
  static const settings = '/settings';
  static const feedback = '/feedback_form';
}