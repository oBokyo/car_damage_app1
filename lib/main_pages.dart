import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'config.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  String _role = 'user';
  bool _isRoleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole =
        (prefs.getString('user_role') ?? 'user').trim().toLowerCase();
    if (mounted) {
      setState(() {
        _role = savedRole;
        _isRoleLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRoleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isExpert = (_role == 'technician' || _role == 'admin');

    final List<Widget> pages = isExpert
        ? [const HistoryPage(isTech: true), const FeedbackHistoryPage()]
        : [
            HomePage(
                onNavigate: (index) => setState(() => _currentIndex = index)),
            const UploadPage(),
            const HistoryPage(isTech: false),
          ];

    final List<NavigationDestination> destinations = isExpert
        ? const [
            NavigationDestination(
              icon: Icon(Icons.engineering_rounded),
              label: 'เคสที่ต้องตรวจสอบ',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_turned_in),
              label: 'ประวัติ Feedback',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'หน้าหลัก',
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud_upload_outlined),
              selectedIcon: Icon(Icons.cloud_upload, color: Color(0xFF2563EB)),
              label: 'อัปโหลด',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              label: 'ประวัติ',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.car_repair, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  const TextSpan(text: 'CarDamage'),
                  const TextSpan(
                    text: 'Detector',
                    style: TextStyle(color: Color(0xFF60A5FA)),
                  ),
                  if (isExpert)
                    const TextSpan(
                      text: ' (Expert)',
                      style: TextStyle(color: Color(0xFFFBBF24), fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDBEAFE),
          destinations: destinations,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomePage({super.key, this.onNavigate});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _totalCount = 0;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() => _userName = prefs.getString('user_name') ?? 'ผู้ใช้งาน');
    }

    try {
      final userId = prefs.getString('user_id') ?? 'unknown';
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}/api/v1/history/$userId'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _totalCount = (data['data'] as List?)?.length ?? 0;
          });
        }
      }
    } on TimeoutException {
      if (mounted) _showErrorSnackBar('หมดเวลาเชื่อมต่อหน้าหลัก กรุณาลองใหม่');
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('ไม่สามารถดึงข้อมูลหน้าหลักได้ กรุณาลองใหม่อีกครั้ง');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEA580C),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _callEmergency(String number) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำลังโทรสายด่วน: $number ...'),
        backgroundColor: const Color(0xFFE11D48),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "สวัสดี, $_userName 👋",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1D4ED8),
                        Color(0xFF4338CA),
                        Color(0xFF0F172A)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 12, color: Color(0xFF93C5FD)),
                            SizedBox(width: 6),
                            Text(
                              "AI-Powered System",
                              style: TextStyle(
                                color: Color(0xFFE0F2FE),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "ระบบตรวจจับและแบ่งส่วน\nรอยเสียหายรถยนต์",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 600 ? 6 : 4;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: [
                        _buildMenuIcon(
                          "ประเมินราคา",
                          Icons.camera_enhance_rounded,
                          const Color(0xFFEFF6FF),
                          const Color(0xFF2563EB),
                          () => widget.onNavigate?.call(1),
                        ),
                        _buildMenuIcon(
                          "ประวัติ",
                          Icons.history_rounded,
                          const Color(0xFFF0FDF4),
                          const Color(0xFF16A34A),
                          () => widget.onNavigate?.call(2),
                        ),
                        _buildMenuIcon(
                          "เคส($_totalCount)",
                          Icons.folder_open_rounded,
                          const Color(0xFFFFF7ED),
                          const Color(0xFFEA580C),
                          () => widget.onNavigate?.call(2),
                        ),
                        _buildMenuIcon(
                          "ตั้งค่า",
                          Icons.settings_rounded,
                          const Color(0xFFF1F5F9),
                          const Color(0xFF475569),
                          () => Navigator.pushNamed(context, AppRoutes.settings),
                        ),
                        _buildMenuIcon(
                          "แจ้งเหตุ (191)",
                          Icons.local_police_rounded,
                          const Color(0xFFFEF2F2),
                          const Color(0xFFE11D48),
                          () => _callEmergency('191'),
                        ),
                        _buildMenuIcon(
                          "กู้ชีพ (1669)",
                          Icons.medical_services_rounded,
                          const Color(0xFFFFF1F2),
                          const Color(0xFFBE123C),
                          () => _callEmergency('1669'),
                        ),
                        _buildMenuIcon(
                          "วิริยะฯ",
                          Icons.shield_rounded,
                          const Color(0xFFF0F9FF),
                          const Color(0xFF0284C7),
                          () => _callEmergency('1557'),
                        ),
                        _buildMenuIcon(
                          "สินมั่นคง",
                          Icons.security_rounded,
                          const Color(0xFFFEFCE8),
                          const Color(0xFFCA8A04),
                          () => _callEmergency('1596'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(String title, IconData icon, Color bgColor,
      Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  XFile? _image;
  Uint8List? _webImage;
  bool _isLoading = false;

  String _selectedVehicle = 'HONDA-CIVIC';
  final List<String> _selectedLocations = ['front_bumper'];

  final List<Map<String, String>> _locationOptions = const [
    {'value': 'front_bumper', 'label': 'กันชนหน้า (Front Bumper)'},
    {'value': 'rear_bumper', 'label': 'กันชนหลัง (Rear Bumper)'},
    {'value': 'door', 'label': 'ประตู (Door)'},
    {'value': 'hood', 'label': 'ฝากระโปรงหน้า (Hood)'},
    {'value': 'trunk', 'label': 'กระโปรงท้าย (Trunk)'},
    {'value': 'fender', 'label': 'ซุ้มล้อ (Fender)'},
    {'value': 'headlight', 'label': 'ไฟหน้า (Headlight)'},
    {'value': 'taillight', 'label': 'ไฟท้าย (Taillight)'},
    {'value': 'windshield_glass', 'label': 'กระจก (Windshield Glass)'},
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      if (kIsWeb) {
        var bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _image = picked;
        });
      } else {
        setState(() => _image = picked);
      }
    }
  }

  void _addLocation() {
    final availableOptions = _locationOptions
        .map((opt) => opt['value']!)
        .where((val) => !_selectedLocations.contains(val))
        .toList();

    if (availableOptions.isNotEmpty) {
      setState(() => _selectedLocations.add(availableOptions.first));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เลือกครบทุกชิ้นส่วนแล้ว')),
      );
    }
  }

  Future<void> _submitInspection() async {
    if ((!kIsWeb && _image == null) || (kIsWeb && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพก่อนวิเคราะห์')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'unknown';

      var req = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/predict'),
      );

      String dbCarModel =
          _selectedVehicle.toLowerCase().contains('civic') ? 'civic' : 'city';

      req.fields['vehicle_id'] = _selectedVehicle;
      req.fields['car_locations'] = jsonEncode(_selectedLocations);
      req.fields['user_id'] = userId;
      req.fields['car_model'] = dbCarModel;

      if (kIsWeb) {
        req.files.add(
          http.MultipartFile.fromBytes('file', _webImage!,
              filename: _image!.name),
        );
      } else {
        req.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      }

      var streamedResponse =
          await req.send().timeout(const Duration(seconds: 120));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var json = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.result, arguments: json);
        }
      } else {
        String errorMessage = 'เกิดข้อผิดพลาดรหัส ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['detail'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFE11D48),
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('เชื่อมต่อเซิร์ฟเวอร์นานเกินไป กรุณาลองใหม่')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "เลือกรุ่นรถยนต์ (Vehicle Model)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicle,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_rounded),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'HONDA-CIVIC', child: Text('HONDA-CIVIC')),
                DropdownMenuItem(
                    value: 'HONDA-CITY', child: Text('HONDA-CITY')),
              ],
              onChanged: (val) => setState(() => _selectedVehicle = val!),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "เลือกชิ้นส่วนรถยนต์",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _addLocation,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("เพิ่มชิ้นส่วน"),
                )
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(_selectedLocations.length, (index) {
              final filteredOptions = _locationOptions.where((opt) {
                return !_selectedLocations.contains(opt['value']) ||
                    opt['value'] == _selectedLocations[index];
              }).toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedLocations[index]),
                        initialValue: _selectedLocations[index],
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.build_circle_outlined),
                        ),
                        items: filteredOptions
                            .map((opt) => DropdownMenuItem(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedLocations[index] = val!),
                      ),
                    ),
                    if (_selectedLocations.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFE11D48),
                        ),
                        onPressed: () =>
                            setState(() => _selectedLocations.removeAt(index)),
                      )
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            const Text(
              "เลือกรูปภาพความเสียหาย",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border:
                      Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ((kIsWeb && _webImage != null) ||
                        (!kIsWeb && _image != null))
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.contain)
                            : Image.file(File(_image!.path),
                                fit: BoxFit.contain),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 54, color: Color(0xFF2563EB)),
                          SizedBox(height: 12),
                          Text(
                            'คลิกเพื่ออัปโหลดรูปภาพ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            'รองรับไฟล์ JPG, PNG',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isLoading ? null : _submitInspection,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.memory_rounded),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'เริ่มวิเคราะห์ความเสียหายด้วย AI',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final bool isTech;
  const HistoryPage({super.key, required this.isTech});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';

  @override
  void initState() {
    super.initState();
    _fetchHistory(showSpinner: true);
  }

  Future<void> _fetchHistory({bool showSpinner = false}) async {
    if (mounted) {
      setState(() {
        _hasError = false;
        if (showSpinner) _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'unknown';

      final String url = widget.isTech
          ? '${AppConfig.baseUrl}/api/v1/review_queue?user_id=$userId'
          : '${AppConfig.baseUrl}/api/v1/history/$userId';

      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _items = data['data'] ?? []);
      } else if (res.statusCode == 403) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'ไม่มีสิทธิ์เข้าถึงข้อมูลส่วนนี้ (กรุณาเข้าสู่ระบบใหม่)';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'เกิดข้อผิดพลาดรหัส ${res.statusCode}';
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'หมดเวลาเชื่อมต่อเซิร์ฟเวอร์';
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
        });
      }
    } finally {
      if (mounted && showSpinner) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFF94A3B8), size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchHistory(showSpinner: true),
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: RefreshIndicator(
          onRefresh: () => _fetchHistory(showSpinner: false),
          child: _items.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    alignment: Alignment.center,
                    child: Text(
                      widget.isTech
                          ? "ไม่มีเคสที่รอการตรวจสอบในขณะนี้"
                          : "ยังไม่มีประวัติในระบบ",
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          "รหัสเคส: #${item['id']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "รหัสรถ: ${item['vehicle_id']}\nวันที่: ${item['created_at']?.toString().split('T').first ?? ''}",
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF2563EB)),
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.inspection,
                            arguments: item,
                          );
                          _fetchHistory(showSpinner: false);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class FeedbackHistoryPage extends StatefulWidget {
  const FeedbackHistoryPage({super.key});
  @override
  State<FeedbackHistoryPage> createState() => _FeedbackHistoryPageState();
}

class _FeedbackHistoryPageState extends State<FeedbackHistoryPage> {
  List _feedbackItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';

  @override
  void initState() {
    super.initState();
    _fetchFeedbackHistory(showSpinner: true);
  }

  Future<void> _fetchFeedbackHistory({bool showSpinner = false}) async {
    if (mounted) {
      setState(() {
        _hasError = false;
        if (showSpinner) _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      final res = await http
          .get(Uri.parse(
              '${AppConfig.baseUrl}/api/v1/feedback_history?user_id=$userId'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _feedbackItems = data['data'] ?? []);
      } else if (res.statusCode == 403) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'ไม่มีสิทธิ์เข้าถึงข้อมูลส่วนนี้';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'เกิดข้อผิดพลาดรหัส ${res.statusCode}';
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'หมดเวลาเชื่อมต่อเซิร์ฟเวอร์';
        });
      }
    } catch (e) {
      debugPrint("Error fetching feedback history: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'ไม่สามารถเชื่อมต่อเครือข่ายได้';
        });
      }
    } finally {
      if (mounted && showSpinner) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFF94A3B8), size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchFeedbackHistory(showSpinner: true),
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: RefreshIndicator(
          onRefresh: () => _fetchFeedbackHistory(showSpinner: false),
          child: _feedbackItems.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    alignment: Alignment.center,
                    child: const Text(
                      "ยังไม่มีประวัติการส่ง Feedback",
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedbackItems.length,
                  itemBuilder: (context, index) {
                    final item = _feedbackItems[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          "อ้างอิงเคส: #${item['case_id']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "แก้ไขเป็น: ${item['damage_label']}",
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "ราคาใหม่: ${item['repair_cost']} บาท",
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                              if (item['note'] != null &&
                                  item['note'].toString().isNotEmpty)
                                Text(
                                  "หมายเหตุ: ${item['note']}",
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.check_circle,
                            color: Color(0xFF059669)),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}