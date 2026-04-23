import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ai_medical_app/services/api_service.dart';

class AISummarizationScreen extends StatefulWidget {
  const AISummarizationScreen({super.key});

  @override
  State<AISummarizationScreen> createState() => _AISummarizationScreenState();
}

class _AISummarizationScreenState extends State<AISummarizationScreen> {
  // ✅ FIX: use ApiService getters so emulator always gets correct host
  String get botBaseUrl  => ApiService.doctorBotUrl;   // port 8001
  String get mainBaseUrl => ApiService.mainBaseUrl;    // port 8000  ← NEW getter (see api_service.dart)

  bool _loadingPatients = true;
  List<Map<String, dynamic>> _approvedPatients = [];

  Map<String, dynamic>? _selectedPatient;
  List<Map<String, dynamic>> _patientRecords = [];
  bool _loadingRecords = false;
  final Set<Map<String, dynamic>> _selectedRecords = {};

  bool _isAnalyzing = false;

  List<Map<String, dynamic>> _perReportResults = [];
  String? _trendSummary;

  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadApprovedPatients();
  }

  Future<void> _loadApprovedPatients() async {
    setState(() => _loadingPatients = true);
    final data = await ApiService.fetchApprovedPatients();
    if (!mounted) return;
    setState(() {
      _approvedPatients = data;
      _loadingPatients = false;
    });
  }

  Future<void> _loadPatientRecords(int patientId) async {
    setState(() {
      _loadingRecords = true;
      _patientRecords = [];
      _selectedRecords.clear();
      _perReportResults = [];
      _trendSummary = null;
      _errorMsg = null;
    });
    final data = await ApiService.fetchPatientRecords(patientId);
    if (!mounted) return;
    setState(() {
      _patientRecords = data;
      _loadingRecords = false;
    });
  }

  void _toggleRecord(Map<String, dynamic> record) {
    setState(() {
      if (_selectedRecords.contains(record)) {
        _selectedRecords.remove(record);
      } else {
        _selectedRecords.add(record);
      }
      _perReportResults = [];
      _trendSummary = null;
      _errorMsg = null;
    });
  }

  Future<void> _analyzeReports() async {
    if (_selectedRecords.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _perReportResults = [];
      _trendSummary = null;
      _errorMsg = null;
    });

    try {
      final patientId = _selectedPatient!['patient_id'].toString();
      final List<Map<String, dynamic>> results = [];

      for (final record in _selectedRecords) {
        final fileUrl = record['file_url'] ?? record['file_path'] ?? '';
        final label = record['title'] ?? record['filename'] ?? 'Report';

        // ✅ FIX: was hardcoded 'http://127.0.0.1:8000/$fileUrl'
        //         now uses ApiService.mainBaseUrl so emulator uses 10.0.2.2
        final fileResponse = await http.get(
          Uri.parse('$mainBaseUrl/$fileUrl'),
        );

        if (fileResponse.statusCode != 200) {
          results.add({'label': label, 'error': 'Could not fetch file.'});
          continue;
        }

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$botBaseUrl/upload_report?patient_id=$patientId'),
        );

        final filename = fileUrl.split('/').last;
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileResponse.bodyBytes,
          filename: filename,
        ));

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          results.add({'label': label, 'result': data});
        } else {
          results.add({'label': label, 'error': 'Bot server error.'});
        }
      }

      String? trend;
      if (_selectedRecords.length > 1) {
        trend = await _fetchTrendSummary(patientId, results);
      }

      if (!mounted) return;
      setState(() {
        _perReportResults = results;
        _trendSummary = trend;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // ✅ FIX: corrected port number in error message (was 8001, doctor bot is 8001 ✓)
        _errorMsg = "Error: Make sure Doctor Bot is running on port 8001!";
        _isAnalyzing = false;
      });
    }
  }

  Future<String?> _fetchTrendSummary(
      String patientId, List<Map<String, dynamic>> results) async {
    try {
      final reports = results
          .where((r) => r.containsKey('result'))
          .map((r) => {
                'label': r['label'],
                'parameters': r['result']['parameters'] ?? {},
                'abnormal': r['result']['abnormal_values'] ?? {},
              })
          .toList();

      if (reports.length < 2) return null;

      final response = await http.post(
        Uri.parse('$botBaseUrl/multi_report_trend?patient_id=$patientId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reports': reports}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['trend_summary'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9575CD),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("AI Medical Summary",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepHeader(
                "1", "Select Approved Patient", const Color(0xFF9575CD)),
            const SizedBox(height: 12),
            _loadingPatients
                ? const Center(child: CircularProgressIndicator())
                : _approvedPatients.isEmpty
                    ? _emptyCard(
                        "No approved patients yet.\nSend access requests first.")
                    : _patientsGrid(),

            if (_selectedPatient != null) ...[
              const SizedBox(height: 24),

              _stepHeader("2", "Select Reports to Analyze", Colors.orange),
              const SizedBox(height: 4),
              Text(
                _selectedRecords.isEmpty
                    ? "Tap to select one or more reports"
                    : "${_selectedRecords.length} report(s) selected",
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedRecords.isEmpty
                      ? Colors.grey
                      : Colors.orange.shade700,
                  fontWeight: _selectedRecords.isEmpty
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _loadingRecords
                  ? const Center(child: CircularProgressIndicator())
                  : _patientRecords.isEmpty
                      ? _emptyCard(
                          "No reports uploaded by this patient yet.")
                      : _recordsList(),
            ],

            if (_selectedRecords.isNotEmpty) ...[
              const SizedBox(height: 24),

              _stepHeader("3", "Analyze Report(s)", Colors.green),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeReports,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9575CD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isAnalyzing
                        ? "Analyzing ${_selectedRecords.length} report(s)..."
                        : "Generate AI Analysis",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],

            if (_errorMsg != null) ...[
              const SizedBox(height: 16),
              _errorCard(_errorMsg!),
            ],

            if (_perReportResults.isNotEmpty) ...[
              const SizedBox(height: 24),
              ..._perReportResults.map((r) {
                if (r.containsKey('error')) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _errorCard("${r['label']}: ${r['error']}"),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildResultCard(
                    label: r['label'] as String,
                    result: r['result'] as Map<String, dynamic>,
                  ),
                );
              }),
            ],

            if (_trendSummary != null) ...[
              const SizedBox(height: 8),
              _buildTrendCard(_trendSummary!),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _patientsGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _approvedPatients.map((p) {
        final name = p['patient_name'] ?? 'Patient';
        final isSelected = _selectedPatient == p;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPatient = p;
              _selectedRecords.clear();
              _perReportResults = [];
              _trendSummary = null;
              _errorMsg = null;
            });
            _loadPatientRecords(p['patient_id'] as int);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xFF9575CD) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF9575CD)
                    : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isSelected
                      ? Colors.white24
                      : const Color(0xFFEDE7F6),
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9575CD),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _recordsList() {
    return Column(
      children: _patientRecords.map((record) {
        final title = record['title'] ?? record['filename'] ?? 'Report';
        final isSelected = _selectedRecords.contains(record);
        return GestureDetector(
          onTap: () => _toggleRecord(record),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEDE7F6)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF9575CD)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF9575CD)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF9575CD)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF9575CD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description,
                      color: Color(0xFF9575CD), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultCard({
    required String label,
    required Map<String, dynamic> result,
  }) {
    final params =
        result['parameters'] as Map<String, dynamic>? ?? {};
    final abnormal =
        result['abnormal_values'] as Map<String, dynamic>? ?? {};
    final summary = result['summary'] ?? 'No summary available';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF9575CD), Color(0xFF4DD0E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF9575CD).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(summary,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5)),
          ),

          if (params.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text("Detected Parameters:",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...params.entries.map((e) {
              final status = abnormal[e.key] ?? 'NORMAL';
              Color statusColor = Colors.green.shade300;
              if (status == 'HIGH') statusColor = Colors.red.shade300;
              if (status == 'LOW')  statusColor = Colors.orange.shade300;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                    Text(e.value.toString(),
                        style:
                            const TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendCard(String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9575CD), width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF9575CD).withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6)),
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
                  color: const Color(0xFF9575CD).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up,
                    color: Color(0xFF9575CD), size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                "Parameter Trend Analysis",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9575CD)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Across ${_selectedRecords.length} selected reports",
            style:
                const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),

          ..._parseTrendBlocks(trend).map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _trendBlock(block),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseTrendBlocks(String trend) {
    final blocks = trend
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    return blocks;
  }

  Widget _trendBlock(String block) {
    final lines = block.split('\n');
    final paramLine = lines.first;
    final bulletLines = lines
        .skip(1)
        .where((l) => l.trim().startsWith('•'))
        .toList();
    final trendLine = lines
        .firstWhere((l) => l.trim().startsWith('→'), orElse: () => '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paramLine.replaceAll(':', '').trim(),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF5E35B1)),
          ),
          const SizedBox(height: 8),

          ...bulletLines.map((line) {
            final clean = line.trim().replaceFirst('•', '').trim();
            Color dotColor = Colors.green;
            if (clean.toLowerCase().contains('high'))
              dotColor = Colors.red;
            if (clean.toLowerCase().contains('low'))
              dotColor = Colors.orange;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(clean,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ),
                ],
              ),
            );
          }),

          if (trendLine.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9575CD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward,
                      size: 14, color: Color(0xFF9575CD)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      trendLine
                          .trim()
                          .replaceFirst('→', '')
                          .replaceFirst('Trend:', '')
                          .trim(),
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5E35B1),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepHeader(String step, String title, Color color) {
    return Row(
      children: [
        CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13))),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: Center(
          child: Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey))),
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}