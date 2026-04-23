import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalReportsScreen extends StatefulWidget {
  const MedicalReportsScreen({super.key});

  @override
  State<MedicalReportsScreen> createState() => _MedicalReportsScreenState();
}

class _MedicalReportsScreenState extends State<MedicalReportsScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  String name = 'Guest User';

  final Color primaryLavender = const Color(0xFF9C89E8);
  final Color darkLavender = const Color(0xFF5E4DB2);
  final Color lightLavender = const Color(0xFFF5F3FF);

  @override
  void initState() {
    super.initState();
    _loadName();
    _fetchRecords();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => name = prefs.getString('patient_name') ?? 'Guest User');
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    final records = await ApiService.fetchMyRecords();
    if (!mounted) return;
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);

    final success = await ApiService.uploadMedicalRecord(_selectedFile!);
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (success) _selectedFile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? "Report uploaded successfully ✅"
          : "Upload failed ❌ — please try again"),
      backgroundColor: success ? Colors.green : Colors.red,
    ));

    if (success) _fetchRecords();
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final recordId = record['id'];
    final recordName = record['title'] ?? 'this record';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Record"),
        content: Text("Are you sure you want to delete \"$recordName\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _records.removeWhere((r) => r['id'] == recordId));

    final success = await ApiService.deleteMedicalRecord(recordId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🗑️ Record deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _fetchRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Failed to delete record"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ FIXED: Open file using mainBaseUrl (10.0.2.2 on Android) + externalApplication
  Future<void> _openFile(String fileUrl) async {
    final fullUrl = '${ApiService.mainBaseUrl}/$fileUrl';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot open file: $fullUrl")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightLavender,
      appBar: AppBar(
        title: const Text("Medical Reports"),
        backgroundColor: primaryLavender,
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 100,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/home'),
            ),
            Builder(builder: (ctx) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              );
            }),
          ],
        ),
      ),
      drawer: AppDrawer(userName: name, currentRoute: '/medical-reports'),
      body: RefreshIndicator(
        onRefresh: _fetchRecords,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildUploadCard(),
            const SizedBox(height: 20),
            _buildRecordsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryLavender.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: primaryLavender),
              const SizedBox(width: 10),
              Text(
                "Upload New Report",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkLavender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFile != null
                      ? primaryLavender
                      : Colors.grey.shade300,
                  width: _selectedFile != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                    color:
                        _selectedFile != null ? primaryLavender : Colors.grey,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.name
                        : "Tap to select PDF, JPG or PNG",
                    style: TextStyle(
                      color:
                          _selectedFile != null ? darkLavender : Colors.grey,
                      fontWeight: _selectedFile != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? "Uploading..." : "Upload Report"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryLavender,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Records",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkLavender,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.folder_open,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text("No records yet",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ...(_records.map((record) => _recordCard(record)).toList()),
      ],
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    final date = record['created_at'] != null
        ? DateTime.tryParse(record['created_at'])
        : null;
    final dateStr = date != null
        ? "${date.day}/${date.month}/${date.year}"
        : "Unknown date";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightLavender,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description, color: primaryLavender),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Uploaded: $dateStr",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          // ✅ FIXED: Use _openFile() which builds correct URL for emulator
          if (record['file_url'] != null)
            IconButton(
              icon: Icon(Icons.open_in_new, color: primaryLavender, size: 20),
              tooltip: "View",
              onPressed: () => _openFile(record['file_url']),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            tooltip: "Delete",
            onPressed: () => _deleteRecord(record),
          ),
        ],
      ),
    );
  }
}