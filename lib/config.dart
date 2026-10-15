import 'package:flutter/foundation.dart';

class AppConfig {
  // 🟢 เมื่อได้ลิงก์จาก Render หรือ Cloudflare Tunnel แล้ว ให้นำมาวางในเครื่องหมายคำพูดด้านล่างนี้
  // ตัวอย่าง: 'https://car-damage-api.onrender.com' (ห้ามมีเครื่องหมาย / ปิดท้าย)
  static const String productionUrl = '';

  static String get baseUrl {
    if (productionUrl.isNotEmpty) {
      return productionUrl;
    }
    if (kIsWeb) return 'http://127.0.0.1:8000';
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