import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_pages.dart';

final String baseUrl = kIsWeb
    ? 'http://127.0.0.1:8000'
    : (defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000');

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "กรุณากรอกอีเมลและรหัสผ่าน");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ""; });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/login'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          final String role = data['role'] ?? 'user'; 

          await prefs.setString('user_email', email);
          await prefs.setString('user_id', data['user_id'].toString());
          await prefs.setString('user_name', data['user_name'] ?? email.split('@').first);
          await prefs.setString('user_role', role);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainNavigator(role: role)),
            );
          }
        } else {
          setState(() => _errorMessage = "อีเมลหรือรหัสผ่านไม่ถูกต้อง");
        }
      } else {
        setState(() => _errorMessage = "อีเมลหรือรหัสผ่านไม่ถูกต้อง");
      }
    } catch (e) {
      setState(() => _errorMessage = "ไม่สามารถเชื่อมต่อระบบหลังบ้านได้ ($e)");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF172554)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.car_crash, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      children: [
                        TextSpan(text: 'CarDamage'),
                        TextSpan(text: 'Detector', style: TextStyle(color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text("ระบบประเมินราคาซ่อมด้วยเทคโนโลยีแบ่งส่วนภาพ", style: TextStyle(color: Color(0xFF64748B), fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 28),

                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECDD3))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_errorMessage, style: const TextStyle(color: Color(0xFFBE123C), fontSize: 13, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),

                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'อีเมล (Email)', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่าน (Password)', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('ยังไม่มีบัญชีใช่ไหม? สร้างบัญชีใหม่', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 14)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = "กรุณากรอกข้อมูลให้ครบถ้วน");
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = "รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ""; });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/register'),
        body: {'full_name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ'), backgroundColor: Color(0xFF059669)),
          );
          Navigator.pop(context);
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorMessage = data['message'] ?? "การลงทะเบียนล้มเหลว");
      }
    } catch (e) {
      setState(() => _errorMessage = "เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างบัญชีใหม่', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.person_add_alt_1_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("สร้างบัญชีใหม่", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 20),

                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECDD3))),
                    child: Text(_errorMessage, style: const TextStyle(color: Color(0xFFBE123C), fontSize: 13)),
                  ),

                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', prefixIcon: Icon(Icons.badge_outlined))),
                const SizedBox(height: 14),
                TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'อีเมล (Email)', prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 14),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่าน (8 ตัวขึ้นไป)', prefixIcon: Icon(Icons.lock_outline))),
                const SizedBox(height: 14),
                TextField(controller: _confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่าน (Confirm)', prefixIcon: Icon(Icons.lock_reset_outlined))),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}