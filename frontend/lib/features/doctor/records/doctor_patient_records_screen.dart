import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'patient_health_timeline_screen.dart';
import 'upload_prescription_screen.dart';

class DoctorPatientRecordsScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const DoctorPatientRecordsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientRecordsScreen> createState() =>
      _DoctorPatientRecordsScreenState();
}

class _DoctorPatientRecordsScreenState
    extends State<DoctorPatientRecordsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];

  // ✅ FIXED: Use ApiService.mainBaseUrl instead of hardcoded 127.0.0.1
  // This returns http://10.0.2.2:8000 on Android emulator automatically
  String get _baseUrl => ApiService.mainBaseUrl;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    final data = await ApiService.fetchPatientRecords(widget.patientId);
    if (!mounted) return;
    setState(() {
      _records = data;
      _isLoading = false;
    });
  }

  // ✅ FIXED: Build full URL with correct host + LaunchMode.externalApplication
  Future<void> _openFile(String fileUrl) async {
    final url = '$_baseUrl/$fileUrl';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot open file: $url")),
      );
    }
  }

  void _goToPrescription() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => UploadPrescriptionScreen(
              patientId: widget.patientId,
              patientName: widget.patientName)));

  void _goToTimeline() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PatientHealthTimelineScreen(
              patientId: widget.patientId,
              patientName: widget.patientName)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        title: Text("${widget.patientName}'s Records"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.timeline),
              tooltip: "Timeline",
              onPressed: _goToTimeline),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _fetchRecords),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToPrescription,
        backgroundColor: const Color(0xFF9C89E8),
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text("Prescription",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _fetchRecords,
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(children: [
                        Expanded(
                            child: _quickActionBanner(
                                icon: Icons.timeline,
                                label: "Timeline",
                                subtitle: "Chronological view",
                                color: const Color(0xFF9C89E8),
                                onTap: _goToTimeline)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _quickActionBanner(
                                icon: Icons.medical_services,
                                label: "Prescription",
                                subtitle: "Upload new",
                                color: Colors.green,
                                onTap: _goToPrescription)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        itemBuilder: (_, i) => _recordCard(_records[i]),
                      ),
                    ),
                  ]),
                ),
    );
  }

  Widget _quickActionBanner(
      {required IconData icon,
      required String label,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [color, color.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 10)),
              ])),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white70, size: 12),
        ]),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.folder_open, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text("No records found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text("${widget.patientName} has not uploaded\nany medical records yet.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _goToPrescription,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C89E8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text("Upload Prescription",
            style: TextStyle(color: Colors.white)),
      ),
    ]));
  }

  Widget _recordCard(Map<String, dynamic> record) {
    final date = record['created_at'] != null
        ? DateTime.tryParse(record['created_at'])
        : null;
    final dateStr = date != null
        ? "${date.day}/${date.month}/${date.year}"
        : 'Unknown date';
    final fileUrl = record['file_url'] ?? '';
    final isImage = fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg') ||
        fileUrl.endsWith('.png');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ✅ FIXED: Image preview uses correct host URL
        if (isImage && fileUrl.isNotEmpty)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              '$_baseUrl/$fileUrl',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: const Color(0xFFEDE7F6),
                  child: const Center(
                      child:
                          Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(
                    isImage ? Icons.image : Icons.picture_as_pdf,
                    color: const Color(0xFF7E6AD6))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(record['title'] ?? 'Untitled',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("Uploaded: $dateStr",
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ])),
            // ✅ FIXED: Uses _openFile() with correct URL
            IconButton(
                icon: const Icon(Icons.open_in_new,
                    color: Color(0xFF9C89E8)),
                onPressed:
                    fileUrl.isNotEmpty ? () => _openFile(fileUrl) : null,
                tooltip: "Open file"),
          ]),
        ),
      ]),
    );
  }
}