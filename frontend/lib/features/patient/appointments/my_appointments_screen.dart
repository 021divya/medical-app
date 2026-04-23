import 'package:flutter/material.dart';
import 'package:ai_medical_app/services/api_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF9C89E8);
  static const Color dark = Color(0xFF5E4DB2);
  static const Color light = Color(0xFFEDE7F6);

  late TabController _tabController;
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _past = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final all = await ApiService.fetchMyAppointments();
    if (!mounted) return;

    final now = DateTime.now();
    final upcoming = <Map<String, dynamic>>[];
    final past = <Map<String, dynamic>>[];

    for (final appt in all) {
      final dateStr = appt['appointment_date'] ?? '';
      final date = DateTime.tryParse(dateStr);
      final isCancelled = appt['status'] == 'cancelled';

      if (!isCancelled && date != null && date.isAfter(now)) {
        upcoming.add(appt);
      } else {
        past.add(appt);
      }
    }

    setState(() {
      _upcoming = upcoming;
      _past = past;
      _isLoading = false;
    });
  }

  Future<void> _cancelAppointment(int id, String bookingId) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment?'),
        content: Text('Booking ID: $bookingId\n\nAre you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.cancelAppointment(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '✅ Appointment cancelled successfully'
          : '❌ Failed to cancel. Try again.'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));

    if (success) _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('My Appointments'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upcoming, size: 16),
                  const SizedBox(width: 6),
                  Text('Upcoming (${_upcoming.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 16),
                  const SizedBox(width: 6),
                  Text('Past (${_past.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _appointmentList(_upcoming, isUpcoming: true),
                _appointmentList(_past, isUpcoming: false),
              ],
            ),
    );
  }

  // ── List view ──────────────────────────────────────────────────────
  Widget _appointmentList(List<Map<String, dynamic>> list,
      {required bool isUpcoming}) {
    if (list.isEmpty) return _emptyState(isUpcoming);

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _appointmentCard(list[i], isUpcoming: isUpcoming),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────
  Widget _emptyState(bool isUpcoming) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUpcoming ? Icons.event_available : Icons.history,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming ? 'No Upcoming Appointments' : 'No Past Appointments',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isUpcoming
                ? 'Book an appointment with a doctor\nfrom the Find Doctors section.'
                : 'Your completed and cancelled\nappointments will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/doctors'),
              icon: const Icon(Icons.search),
              label: const Text('Find Doctors'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Appointment card ───────────────────────────────────────────────
  Widget _appointmentCard(Map<String, dynamic> appt,
      {required bool isUpcoming}) {
    final status = appt['status'] ?? 'confirmed';
    final bookingId = appt['booking_id'] ?? '';
    final doctorName = appt['doctor_name'] ?? 'Unknown Doctor';
    final doctorSpec = appt['doctor_speciality'] ?? '';
    final date = appt['appointment_date'] ?? '';
    final slot = appt['appointment_slot'] ?? '';
    final visitType = appt['visit_type'] ?? '';
    final amount = appt['amount_paid'] ?? 0;
    final payMethod = appt['payment_method'] ?? '';
    final patientName = appt['patient_name'] ?? '';
    final id = appt['id'] as int? ?? 0;

    // Format date nicely
    final parsedDate = DateTime.tryParse(date);
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final displayDate = parsedDate != null
        ? '${parsedDate.day} ${months[parsedDate.month]} ${parsedDate.year}'
        : date;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: status == 'confirmed'
              ? Colors.green.shade200
              : status == 'cancelled'
                  ? Colors.red.shade200
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Doctor + status row ──────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: light,
                  child: Text(
                    doctorName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. $doctorName',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (doctorSpec.isNotEmpty)
                        Text(doctorSpec,
                            style: const TextStyle(
                                color: primary, fontSize: 12)),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 12),

            // ── Appointment details ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.calendar_today, 'Date', displayDate),
                  const SizedBox(height: 6),
                  _detailRow(Icons.access_time, 'Time', slot),
                  const SizedBox(height: 6),
                  _detailRow(
                    visitType == 'Video Consult'
                        ? Icons.videocam
                        : Icons.local_hospital,
                    'Type',
                    visitType,
                  ),
                  const SizedBox(height: 6),
                  _detailRow(Icons.person, 'Patient', patientName),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Payment + Booking ID row ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.currency_rupee, size: 14, color: Colors.grey),
                  Text('$amount  •  ${payMethod.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ]),
                Row(children: [
                  const Icon(Icons.confirmation_number,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(bookingId,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                ]),
              ],
            ),

            // ── Cancel button (only for upcoming confirmed) ──────
            if (isUpcoming && status == 'confirmed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelAppointment(id, bookingId),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: Colors.red),
                  label: const Text('Cancel Appointment',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}