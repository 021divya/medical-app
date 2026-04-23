import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_medical_app/services/api_service.dart';

class PatientHealthTimelineScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientHealthTimelineScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientHealthTimelineScreen> createState() =>
      _PatientHealthTimelineScreenState();
}

class _PatientHealthTimelineScreenState
    extends State<PatientHealthTimelineScreen> {
  // ✅ FIXED: Use ApiService.mainBaseUrl (10.0.2.2:8000 on Android emulator)
  String get _baseUrl => ApiService.mainBaseUrl;

  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];

  static const int _gapWarningDays = 30;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    final data = await ApiService.fetchPatientRecords(widget.patientId);
    if (!mounted) return;

    data.sort((a, b) {
      final da =
          DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final db =
          DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return da.compareTo(db);
    });

    setState(() {
      _records = data;
      _isLoading = false;
    });
  }

  // ✅ FIXED: Uses _baseUrl getter + LaunchMode.externalApplication
  Future<void> _openFile(String fileUrl) async {
    final uri = Uri.parse('$_baseUrl/$fileUrl');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot open file: $fileUrl")),
      );
    }
  }

  List<Map<String, dynamic>> _buildTimelineItems() {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < _records.length; i++) {
      final record = _records[i];
      final date =
          DateTime.tryParse(record['created_at'] ?? '') ?? DateTime.now();
      if (i > 0) {
        final prevDate =
            DateTime.tryParse(_records[i - 1]['created_at'] ?? '') ??
                DateTime.now();
        final gap = date.difference(prevDate).inDays;
        if (gap > _gapWarningDays) {
          items.add({'type': 'gap', 'days': gap});
        }
      }
      items.add({'type': 'record', 'data': record, 'date': date});
    }
    return items;
  }

  Map<String, dynamic> _computeStats() {
    if (_records.isEmpty) return {};

    final dates = _records
        .map((r) => DateTime.tryParse(r['created_at'] ?? ''))
        .whereType<DateTime>()
        .toList();
    dates.sort();

    final first = dates.first;
    final last = dates.last;
    final spanDays = last.difference(first).inDays;

    int maxGap = 0;
    int totalGap = 0;
    for (int i = 1; i < dates.length; i++) {
      final g = dates[i].difference(dates[i - 1]).inDays;
      if (g > maxGap) maxGap = g;
      totalGap += g;
    }
    final avgGap =
        dates.length > 1 ? (totalGap / (dates.length - 1)).round() : 0;

    final imageCount = _records.where((r) {
      final url = r['file_url'] ?? '';
      return url.endsWith('.jpg') ||
          url.endsWith('.jpeg') ||
          url.endsWith('.png');
    }).length;
    final pdfCount = _records.length - imageCount;

    return {
      'total': _records.length,
      'first': first,
      'last': last,
      'spanDays': spanDays,
      'maxGap': maxGap,
      'avgGap': avgGap,
      'imageCount': imageCount,
      'pdfCount': pdfCount,
    };
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
            const Text("Health Timeline",
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.patientName,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRecords,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _fetchRecords,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildStatsBanner()),
                      SliverToBoxAdapter(child: _buildLegend()),
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final items = _buildTimelineItems();
                              if (index >= items.length) return null;
                              final item = items[index];
                              final isLast = index == items.length - 1;

                              if (item['type'] == 'gap') {
                                return _gapNode(item['days'] as int);
                              }
                              return _recordNode(
                                record:
                                    item['data'] as Map<String, dynamic>,
                                date: item['date'] as DateTime,
                                index: _records
                                    .indexOf(item['data']),
                                isLast: isLast,
                              );
                            },
                            childCount: _buildTimelineItems().length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsBanner() {
    final s = _computeStats();
    if (s.isEmpty) return const SizedBox();

    final first = s['first'] as DateTime;
    final last = s['last'] as DateTime;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C89E8), Color(0xFF7E6AD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C89E8).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Monitoring Overview",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip(
                  Icons.folder_copy, "${s['total']}", "Reports"),
              const SizedBox(width: 10),
              _statChip(Icons.date_range, "${s['spanDays']}d", "Span"),
              const SizedBox(width: 10),
              _statChip(
                  Icons.timelapse, "${s['avgGap']}d", "Avg gap"),
              const SizedBox(width: 10),
              _statChip(
                  Icons.warning_amber,
                  s['maxGap'] > _gapWarningDays
                      ? "⚠️ ${s['maxGap']}d"
                      : "${s['maxGap']}d",
                  "Max gap"),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  color: Colors.white54, size: 10),
              const SizedBox(width: 6),
              Text("First: ${_fmt(first)}",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.fiber_manual_record,
                  color: Colors.white54, size: 10),
              const SizedBox(width: 6),
              Text("Latest: ${_fmt(last)}",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _legendItem(
              const Color(0xFF9C89E8), "Report uploaded"),
          const SizedBox(width: 16),
          _legendItem(Colors.orange.shade400,
              "Monitoring gap > 30 days"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _recordNode({
    required Map<String, dynamic> record,
    required DateTime date,
    required int index,
    required bool isLast,
  }) {
    final fileUrl = record['file_url'] ?? '';
    final isImage = fileUrl.endsWith('.jpg') ||
        fileUrl.endsWith('.jpeg') ||
        fileUrl.endsWith('.png');
    final title = record['title'] ?? 'Untitled';
    final isLeft = index.isEven;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 72,
            child: isLeft
                ? _dateLabel(date)
                : Column(children: [
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                              width: 2,
                              color: const Color(0xFFD1C4E9)),
                        ),
                      ),
                  ]),
          ),
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C89E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C89E8).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 2, color: const Color(0xFFD1C4E9)),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLeft) _dateLabel(date),
                  _recordCard(
                    record: record,
                    title: title,
                    fileUrl: fileUrl,
                    isImage: isImage,
                    date: date,
                    index: index,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateLabel(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_monthAbbr(date.month),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C89E8))),
          Text("${date.day}",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E35B1))),
          Text("${date.year}",
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _recordCard({
    required Map<String, dynamic> record,
    required String title,
    required String fileUrl,
    required bool isImage,
    required DateTime date,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ FIXED: Image preview uses correct host URL
          if (isImage && fileUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: Image.network(
                '$_baseUrl/$fileUrl',
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60,
                  color: const Color(0xFFEDE7F6),
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      isImage
                          ? Icons.image
                          : Icons.picture_as_pdf,
                      color: const Color(0xFF7E6AD6),
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(_fmt(date),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                // ✅ FIXED: Uses _openFile() with correct URL
                IconButton(
                  icon: const Icon(Icons.open_in_new,
                      color: Color(0xFF9C89E8), size: 20),
                  onPressed: fileUrl.isNotEmpty
                      ? () => _openFile(fileUrl)
                      : null,
                  tooltip: "Open file",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gapNode(int days) {
    final months = (days / 30).floor();
    final label = months >= 1
        ? "$months month${months > 1 ? 's' : ''} gap"
        : "$days day gap";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 72),
          Column(
            children: [
              Container(width: 2, height: 12, color: Colors.orange.shade200),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 11),
              ),
              Container(width: 2, height: 12, color: Colors.orange.shade200),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "⚠️ $label — no reports in this period",
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("No records yet",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "${widget.patientName} has not uploaded\nany medical records yet.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => "${d.day} ${_monthAbbr(d.month)} ${d.year}";

  String _monthAbbr(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}