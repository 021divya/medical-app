import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_medical_app/services/api_service.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const UploadPrescriptionScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  // ✅ FIXED: Use ApiService.mainBaseUrl — gives 10.0.2.2 on Android emulator
  String get _baseUrl => ApiService.mainBaseUrl;

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _successMsg;
  String? _errorMsg;

  bool _loadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final data =
        await ApiService.fetchPrescriptionsForPatient(widget.patientId);
    if (!mounted) return;
    setState(() {
      _history = data;
      _loadingHistory = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _clearFile() => setState(() => _pickedFile = null);

  // ✅ FIXED: Builds correct URL using _baseUrl getter + LaunchMode.externalApplication
  Future<void> _openFile(String fileUrl) async {
    final fullUrl =
        fileUrl.startsWith('http') ? fileUrl : '$_baseUrl/$fileUrl';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot open: $fullUrl")),
      );
    }
  }

  Future<void> _upload() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMsg = "Please enter a prescription title.");
      return;
    }

    setState(() {
      _isUploading = true;
      _successMsg = null;
      _errorMsg = null;
    });

    final ok = await ApiService.uploadPrescription(
      patientId: widget.patientId,
      title: title,
      notes: _notesController.text.trim(),
      file: _pickedFile,
    );

    if (!mounted) return;

    if (ok) {
      _titleController.clear();
      _notesController.clear();
      setState(() {
        _pickedFile = null;
        _isUploading = false;
        _successMsg = "✅ Prescription uploaded successfully!";
        _errorMsg = null;
      });
      await _loadHistory();
    } else {
      setState(() {
        _isUploading = false;
        _errorMsg = "❌ Upload failed. Please try again.";
        _successMsg = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            const Text("Upload Prescription",
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.patientName,
                style:
                    const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
                Icons.upload_file, "New Prescription", const Color(0xFF9C89E8)),
            const SizedBox(height: 14),
            _buildForm(),

            if (_successMsg != null) ...[
              const SizedBox(height: 14),
              _feedbackBanner(_successMsg!, isSuccess: true),
            ],
            if (_errorMsg != null) ...[
              const SizedBox(height: 14),
              _feedbackBanner(_errorMsg!, isSuccess: false),
            ],

            const SizedBox(height: 28),
            _sectionHeader(
                Icons.history, "Previously Issued", Colors.green),
            const SizedBox(height: 14),
            _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? _emptyHistory()
                    : _historyList(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person,
                    color: Color(0xFF9C89E8), size: 16),
                const SizedBox(width: 6),
                Text(
                  "For: ${widget.patientName}",
                  style: const TextStyle(
                      color: Color(0xFF5E35B1),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _label("Prescription Title *"),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration(
                "e.g. Post-consultation prescription", Icons.title),
          ),
          const SizedBox(height: 16),
          _label("Doctor's Notes (optional)"),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: _inputDecoration(
                "Dosage instructions, warnings, follow-up...",
                Icons.notes),
          ),
          const SizedBox(height: 18),
          _label("Attach File (optional — PDF / Image)"),
          const SizedBox(height: 8),
          _filePicker(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C89E8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(
                _isUploading ? "Uploading..." : "Upload Prescription",
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filePicker() {
    if (_pickedFile != null) {
      final isImage = ['jpg', 'jpeg', 'png']
          .any((ext) => _pickedFile!.name.toLowerCase().endsWith(ext));
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF9C89E8)),
        ),
        child: Row(
          children: [
            Icon(isImage ? Icons.image : Icons.picture_as_pdf,
                color: const Color(0xFF9C89E8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_pickedFile!.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: _clearFile,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF9C89E8).withOpacity(0.4), width: 1.5),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.upload_file, color: Color(0xFF9C89E8), size: 28),
              SizedBox(height: 6),
              Text("Tap to attach PDF or image",
                  style:
                      TextStyle(color: Color(0xFF9575CD), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyList() {
    return Column(
      children: _history.map((p) => _historyCard(p)).toList(),
    );
  }

  Widget _historyCard(Map<String, dynamic> p) {
    final date = p['created_at'] != null
        ? DateTime.tryParse(p['created_at'].toString())
        : null;
    final dateStr = date != null
        ? "${date.day}/${date.month}/${date.year}"
        : 'Unknown date';
    final fileUrl = (p['file_url'] ?? '').toString().trim();
    final hasFile = fileUrl.isNotEmpty;
    final notes = (p['notes'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.medical_services,
                    color: Colors.green.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title'] ?? 'Prescription',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text("Issued: $dateStr",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              // ✅ FIXED: Uses _openFile() with correct URL
              if (hasFile)
                IconButton(
                  icon: const Icon(Icons.open_in_new,
                      color: Color(0xFF9C89E8), size: 20),
                  onPressed: () => _openFile(fileUrl),
                  tooltip: "Open file",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(notes,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black87, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87));

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF9C89E8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF3EFFF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF9C89E8), width: 1.5)),
    );
  }

  Widget _feedbackBanner(String msg, {required bool isSuccess}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isSuccess
                ? Colors.green.shade300
                : Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: isSuccess
                        ? Colors.green.shade800
                        : Colors.red.shade800)),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: const Center(
        child: Text(
          "No prescriptions issued yet.\nUse the form above to upload one.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}