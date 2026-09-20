import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'auth_pages.dart'; 

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inspection = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    Uint8List? imageBytes;
    final imgUrl = inspection['image_url']?.toString() ?? '';
    if (imgUrl.startsWith('data:image')) {
      try {
        imageBytes = base64Decode(imgUrl.split(',').last);
      } catch (_) {
        imageBytes = null;
      }
    }

    final damages = (inspection['damage_labels'] as List?) ?? [];
    double totalCost = double.tryParse(inspection['total_cost']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('ผลการวิเคราะห์ AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF059669)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "AI ประมวลผลสำเร็จ กรุณาตรวจสอบผลการประเมิน",
                      style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text("ภาพ Segmentation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
              child: imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(imageBytes, fit: BoxFit.contain),
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported_rounded, color: Colors.white38, size: 64),
                    ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("รายการประเมินความเสียหาย", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 24),
                  if (damages.isEmpty)
                    const Text("ไม่พบความเสียหายในภาพนี้", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold))
                  else
                    ...damages.map((d) {
                      final String label = d['label']?.toString() ?? 'unknown';
                      final String cost = d['cost']?.toString() ?? '0';
                      final String percent = d['damage_percent']?.toString() ?? '0';
                      final String action = d['repair_action']?.toString() ?? 'รอช่างประเมิน';
                      final bool isReplace = action.contains('เปลี่ยน');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  "$cost ฿",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            if (d.containsKey('damage_percent'))
                              Padding(
                                padding: const EdgeInsets.only(left: 24, top: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      "พื้นที่เสียหาย: $percent% | ",
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    Text(
                                      "วิธีซ่อม: $action",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isReplace ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ยอดประเมินรวม:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text(
                          "${totalCost.toStringAsFixed(2)} THB",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('เสร็จสิ้น / กลับหน้าหลัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key});

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'user';
    });
  }

  @override
  Widget build(BuildContext context) {
    final inspection = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    Uint8List? imageBytes;
    final imgUrl = inspection['image_url']?.toString() ?? '';
    if (imgUrl.startsWith('data:image')) {
      try {
        imageBytes = base64Decode(imgUrl.split(',').last);
      } catch (_) {
        imageBytes = null;
      }
    }

    final damages = (inspection['damage_labels'] as List?) ?? [];
    double totalCost = double.tryParse(inspection['total_cost']?.toString() ?? '0') ?? 0.0;
    if (totalCost == 0.0 && damages.isNotEmpty) {
      for (var d in damages) {
        totalCost += double.tryParse(d['cost'].toString()) ?? 0;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('รายละเอียดเคส #${inspection['id'] ?? ''}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text("รหัสรถ: ${inspection['vehicle_id'] ?? 'unknown'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("สร้างเมื่อ: ${inspection['created_at']?.toString().split('T').first ?? '-'}",
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text("ภาพความเสียหาย", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
              child: imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(imageBytes, fit: BoxFit.contain),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_rounded, color: Colors.white38, size: 54),
                          SizedBox(height: 8),
                          Text("ไม่พบไฟล์รูปภาพในเคสนี้", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("รายการความเสียหาย", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 24),
                  if (damages.isEmpty)
                    const Text("ไม่พบความเสียหายในเคสนี้", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold))
                  else
                    ...damages.map((d) {
                      final String label = d['label']?.toString() ?? 'unknown';
                      final String cost = d['cost']?.toString() ?? '0';
                      final String percent = d['damage_percent']?.toString() ?? '0';
                      final String action = d['repair_action']?.toString() ?? 'รอช่างประเมิน';
                      final bool isReplace = action.contains('เปลี่ยน');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text("${cost} ฿", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (d.containsKey('damage_percent'))
                              Padding(
                                padding: const EdgeInsets.only(left: 24, top: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      "พื้นที่เสียหาย: $percent% | ",
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    Text(
                                      "วิธีซ่อม: $action",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isReplace ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ยอดรวม:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text("${totalCost.toStringAsFixed(2)} THB",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_userRole == 'technician' || _userRole == 'admin')
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/feedback_form',
                    arguments: inspection['id'].toString(), 
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
                label: const Text('ส่ง Feedback (สำหรับช่าง/แอดมิน)', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15)),
              ),
          ],
        ),
      ),
    );
  }
}

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});
  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _caseIdController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  String _damageType = 'dent';
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final caseIdArg = ModalRoute.of(context)?.settings.arguments as String?;
    if (caseIdArg != null && _caseIdController.text.isEmpty) {
      _caseIdController.text = "CASE-$caseIdArg";
    }
  }

  Future<void> _submitFeedback() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกราคาประเมินใหม่')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/feedback'),
        body: {
          'case_id': _caseIdController.text,
          'damage_type': _damageType,
          'corrected_price': _priceController.text,
          'notes': _notesController.text,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึก Feedback เรียบร้อยแล้ว!'), backgroundColor: Color(0xFF059669)),
          );
          Navigator.pop(context); 
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ส่ง Feedback ให้ช่าง')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ยืนยันหรือแก้ไขข้อมูลโดยช่าง", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text("ข้อมูลที่แก้ไขจะถูกใช้เพิ่มความแม่นยำให้ AI โมเดล", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 24),

            TextField(
              controller: _caseIdController,
              readOnly: true, 
              decoration: InputDecoration(
                labelText: 'รหัสอ้างอิงเคส (Case ID)',
                filled: true,
                fillColor: Colors.grey.shade200, 
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _damageType,
              decoration: const InputDecoration(labelText: 'ประเภทความเสียหายที่ถูกต้อง'),
              items: const [
                DropdownMenuItem(value: 'dent', child: Text('รอยบุบ (dent)')),
                DropdownMenuItem(value: 'crack', child: Text('รอยแตก (crack)')),
                DropdownMenuItem(value: 'scratch', child: Text('รอยขีดข่วน (scratch)')),
                DropdownMenuItem(value: 'lamp_broken', child: Text('ไฟแตก (lamp broken)')),
                DropdownMenuItem(value: 'glass_shatter', child: Text('กระจกแตก (glass shatter)')),
                DropdownMenuItem(value: 'no_damage', child: Text('ไม่มีความเสียหาย')),
              ],
              onChanged: (v) => setState(() => _damageType = v!),
            ),
            const SizedBox(height: 16),

            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ราคาประเมินใหม่ที่ถูกต้อง (บาท)')),
            const SizedBox(height: 16),

            TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'หมายเหตุเพิ่มเติม')),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isLoading ? null : _submitFeedback,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_rounded),
              label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('บันทึก Feedback ลงฐานข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isProfileLoading = false;
  bool _isPasswordLoading = false;
  String _userId = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
      _nameController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
    });
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isProfileLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/update_profile'),
        body: {'user_id': _userId, 'full_name': _nameController.text.trim()},
      );
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text.trim());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตชื่อสำเร็จ!'), backgroundColor: Colors.green));
      }
    } catch (e) {} finally {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสผ่านใหม่ไม่ตรงกัน!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isPasswordLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/update_password'),
        body: {
          'user_id': _userId,
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        },
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ!'), backgroundColor: Colors.green));
          _currentPasswordController.clear(); _newPasswordController.clear(); _confirmPasswordController.clear();
        }
      }
    } catch (e) {} finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่าบัญชี')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลส่วนตัว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, enabled: false, decoration: const InputDecoration(labelText: 'อีเมล', prefixIcon: Icon(Icons.email_outlined), filled: true, fillColor: Color(0xFFF1F5F9))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isProfileLoading ? null : _updateProfile,
                    icon: _isProfileLoading ? const SizedBox.shrink() : const Icon(Icons.save),
                    label: _isProfileLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('บันทึกข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: _currentPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่านปัจจุบัน', prefixIcon: Icon(Icons.lock_outline))),
                  const SizedBox(height: 16),
                  TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่', prefixIcon: Icon(Icons.vpn_key_outlined))),
                  const SizedBox(height: 16),
                  TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่านใหม่', prefixIcon: Icon(Icons.vpn_key_outlined))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isPasswordLoading ? null : _updatePassword,
                    icon: _isPasswordLoading ? const SizedBox.shrink() : const Icon(Icons.shield_outlined),
                    label: _isPasswordLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('อัปเดตรหัสผ่าน', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.shade200)),
              tileColor: Colors.red.shade50,
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48)),
              title: const Text('ออกจากระบบ', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); 
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}