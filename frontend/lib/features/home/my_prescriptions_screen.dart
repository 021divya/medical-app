import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  // ✅ FIXED: Platform-aware base URL — mirrors ApiService._getHost()
  static String get _baseUrl {
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://127.0.0.1:8000";
  }

  static const Color primary = Color(0xFF9C89E8);
  static const Color dark = Color(0xFF5E4DB2);
  static const Color lightBg = Color(0xFFF5F3FF);

  bool _isLoading = true;
  String _errorMsg = '';
  List<Map<String, dynamic>> _prescriptions = [];
  String _name = 'Guest User';

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadName();
    _fetchPrescriptions();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _name = prefs.getString('patient_name') ?? 'Guest User');
  }

  Future<void> _fetchPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final data = await ApiService.fetchMyPrescriptions();
      if (!mounted) return;
      setState(() {
        _prescriptions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'Failed to load prescriptions. Pull to refresh.';
      });
    }
  }

  Future<void> _openFile(String fileUrl) async {
    // ✅ FIXED: Replace any 127.0.0.1 in server-returned URLs with the correct host
    String resolvedUrl;
    if (fileUrl.startsWith('http')) {
      // Server may return http://127.0.0.1:8000/... — fix it for emulator
      resolvedUrl = fileUrl.replaceFirst(
        RegExp(r'http://127\.0\.0\.1'),
        Platform.isAndroid ? 'http://10.0.2.2' : 'http://127.0.0.1',
      );
    } else {
      // Relative path — prepend platform-aware base URL
      final cleanPath = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
      resolvedUrl = '${_baseUrl}$cleanPath';
    }

    final uri = Uri.parse(resolvedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot open: $resolvedUrl")),
      );
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _prescriptions;
    return _prescriptions.where((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final doctor = (p['doctor_name'] ?? '').toString().toLowerCase();
      final notes = (p['notes'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery) ||
          doctor.contains(_searchQuery) ||
          notes.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "My Prescriptions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _fetchPrescriptions,
          ),
        ],
      ),
      drawer: AppDrawer(userName: _name, currentRoute: '/prescriptions'),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search by title, doctor or notes…",
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg.isNotEmpty) {
      return _errorState();
    }

    if (_prescriptions.isEmpty) {
      return _emptyState();
    }

    final list = _filtered;
    if (list.isEmpty) {
      return _noResultsState();
    }

    return RefreshIndicator(
      onRefresh: _fetchPrescriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _prescriptionCard(list[i]),
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _fetchPrescriptions,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Column(
            children: [
              Icon(Icons.medication_outlined,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text("No Prescriptions Yet",
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Prescriptions issued by your doctors\nwill appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchPrescriptions,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(backgroundColor: primary),
          ),
        ],
      ),
    );
  }

  Widget _noResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No results for "$_searchQuery"',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _prescriptionCard(Map<String, dynamic> p) {
    final date = p['created_at'] != null
        ? DateTime.tryParse(p['created_at'].toString())
        : null;
    final dateStr =
        date != null ? "${date.day}/${date.month}/${date.year}" : 'Unknown date';
    final doctorName = (p['doctor_name'] ?? 'Your Doctor').toString();
    final title = (p['title'] ?? 'Prescription').toString();
    final notes = (p['notes'] ?? '').toString().trim();
    final fileUrl = (p['file_url'] ?? '').toString().trim();
    final hasFile = fileUrl.isNotEmpty;
    final hasNotes = notes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, Color(0xFFB39DDB)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_services,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text("Dr. $doctorName",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasNotes) ...[
                  Row(
                    children: [
                      const Icon(Icons.notes, color: dark, size: 16),
                      const SizedBox(width: 6),
                      const Text("Doctor's Notes",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dark,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(notes,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                ],
                if (!hasFile && !hasNotes)
                  const Text("No additional details provided.",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                if (hasFile) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openFile(fileUrl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(color: primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text("Open Attached File",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attachment, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Text("No file attached",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}