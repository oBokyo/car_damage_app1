import 'package:flutter_test/flutter_test.dart';
import 'package:car_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // ทดสอบการสร้างหน้าจอเริ่มต้น (สถานะยังไม่ได้ล็อกอิน)
    await tester.pumpWidget(const CarDamageApp(isLoggedIn: false));

    // ตรวจสอบว่ามีข้อความหน้าเข้าสู่ระบบแสดงผลขึ้นมาอย่างถูกต้อง
    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
  });
}