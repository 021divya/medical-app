import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'doctor_model.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime appointmentDate;
  final String appointmentSlot;
  final String visitType;
  final String patientName;
  final String patientPhone;
  final String bookingId;
  final int amountPaid;
  final String paymentMethod;

  const BookingConfirmationScreen({
    super.key,
    required this.doctor,
    required this.appointmentDate,
    required this.appointmentSlot,
    required this.visitType,
    required this.patientName,
    required this.patientPhone,
    required this.bookingId,
    required this.amountPaid,
    required this.paymentMethod,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  static const Color primary = Color(0xFF9C89E8);
  static const Color dark = Color(0xFF5E4DB2);
  static const Color light = Color(0xFFEDE7F6);

  late AnimationController _checkController;
  late AnimationController _fadeController;
  late Animation<double> _checkAnim;
  late Animation<double> _fadeAnim;

  bool _bookingSaved = false;
  bool _savingBooking = true;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkAnim =
        CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });

    HapticFeedback.heavyImpact();

    // ✅ Save booking to backend after payment
    _saveBookingToBackend();
  }

  // ✅ Save to backend so My Appointments gets updated
  Future<void> _saveBookingToBackend() async {
    final regNo =
        'MCI-${widget.doctor.name.hashCode.abs() % 90000 + 10000}';
    final dateStr =
        '${widget.appointmentDate.year}-${widget.appointmentDate.month.toString().padLeft(2, '0')}-${widget.appointmentDate.day.toString().padLeft(2, '0')}';

    final result = await ApiService.bookAppointment(
      doctorName: widget.doctor.name,
      doctorRegNo: regNo,
      doctorSpeciality: widget.doctor.speciality,
      appointmentDate: dateStr,
      appointmentSlot: widget.appointmentSlot,
      visitType: widget.visitType,
      patientName: widget.patientName,
      patientPhone: widget.patientPhone,
      reason: '',
      amountPaid: widget.amountPaid,
      paymentMethod: widget.paymentMethod,
      bookingId: widget.bookingId,
    );

    if (mounted) {
      setState(() {
        _bookingSaved = result != null;
        _savingBooking = false;
      });
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _paymentMethodLabel {
    switch (widget.paymentMethod) {
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Debit/Credit Card';
      case 'netbanking':
        return 'Net Banking';
      case 'wallet':
        return 'Digital Wallet';
      default:
        return widget.paymentMethod;
    }
  }

  // ✅ Show printable ticket in a dialog (works on web + mobile)
  void _showPrintableTicket() {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final regNo =
        'MCI-${widget.doctor.name.hashCode.abs() % 90000 + 10000}';
    final displayDate =
        '${widget.appointmentDate.day} ${months[widget.appointmentDate.month]} ${widget.appointmentDate.year}';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primary, dark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_hospital,
                          color: Colors.white, size: 32),
                      const SizedBox(height: 6),
                      const Text('MEDICO AI',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2)),
                      const Text('Appointment Confirmation',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Booking ID chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Booking ID: ${widget.bookingId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dark,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),

                // Details table
                _ticketRow('Doctor',
                    'Dr. ${widget.doctor.name}'),
                _ticketRow('Speciality', widget.doctor.speciality),
                _ticketRow('Reg No', regNo),
                const Divider(height: 20),
                _ticketRow('Patient', widget.patientName),
                _ticketRow('Phone', widget.patientPhone),
                const Divider(height: 20),
                _ticketRow('Date', displayDate),
                _ticketRow('Time', widget.appointmentSlot),
                _ticketRow('Type', widget.visitType),
                _ticketRow('Address', widget.doctor.address),
                const Divider(height: 20),
                _ticketRow('Amount Paid', '₹${widget.amountPaid}'),
                _ticketRow('Payment', _paymentMethodLabel),
                const SizedBox(height: 20),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 6),
                      Text('CONFIRMED',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please show this at the clinic',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 20),

                // Copy + Close buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final text =
                            'MEDICO AI - Appointment Confirmation\n'
                            'Booking ID: ${widget.bookingId}\n'
                            'Doctor: Dr. ${widget.doctor.name} (${widget.doctor.speciality})\n'
                            'Reg No: $regNo\n'
                            'Patient: ${widget.patientName}\n'
                            'Phone: ${widget.patientPhone}\n'
                            'Date: $displayDate at ${widget.appointmentSlot}\n'
                            'Type: ${widget.visitType}\n'
                            'Address: ${widget.doctor.address}\n'
                            'Amount Paid: ₹${widget.amountPaid} via $_paymentMethodLabel\n'
                            'Status: CONFIRMED';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Ticket copied to clipboard!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16, color: primary),
                      label: const Text('Copy',
                          style: TextStyle(color: primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ),
          const Text(': ',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F3FF),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _successHeader(),
              // ✅ Show saving status
              if (_savingBooking)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Saving your booking...',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              if (!_savingBooking && !_bookingSaved)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Could not save to server. Check your connection.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ]),
                ),
              _detailsCard(),
              const SizedBox(height: 16),
              _paymentCard(),
              const SizedBox(height: 16),
              _importantNotes(),
              const SizedBox(height: 24),
              _actionButtons(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successHeader() {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C89E8), Color(0xFF5E4DB2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _checkAnim,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child:
                  const Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const Text('Booking Confirmed! 🎉',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Your appointment with Dr. ${widget.doctor.name}\nis confirmed for ${widget.appointmentDate.day} ${months[widget.appointmentDate.month]}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text('Booking ID: ${widget.bookingId}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final regNo =
        'MCI-${widget.doctor.name.hashCode.abs() % 90000 + 10000}';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.event_available, color: primary, size: 20),
              const SizedBox(width: 8),
              const Text('Appointment Summary',   // ✅ RENAMED
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Divider(height: 20),
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: light,
                child: Text(
                  widget.doctor.name[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: dark),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${widget.doctor.name}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.doctor.speciality,
                        style: const TextStyle(
                            color: primary, fontSize: 13)),
                    Row(children: [
                      const Icon(Icons.verified,
                          size: 13, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('Reg: $regNo',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ]),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _detailRow(Icons.person, 'Patient', widget.patientName),
            _detailRow(Icons.phone, 'Phone', widget.patientPhone),
            _detailRow(
              Icons.calendar_today,
              'Date',
              '${widget.appointmentDate.day} ${months[widget.appointmentDate.month]} ${widget.appointmentDate.year}',
            ),
            _detailRow(Icons.access_time, 'Time', widget.appointmentSlot),
            _detailRow(
              widget.visitType == 'Video Consult'
                  ? Icons.videocam
                  : Icons.local_hospital,
              'Type',
              widget.visitType,
            ),
            _detailRow(
                Icons.location_on, 'Address', widget.doctor.address),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.check_circle,
                  color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text('Payment Successful',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green.shade700)),
            ]),
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Paid',
                      style: TextStyle(color: Colors.grey)),
                  Text('₹${widget.amountPaid}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
            const SizedBox(height: 4),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  Text(_paymentMethodLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13)),
                ]),
            const SizedBox(height: 4),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction ID',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.bookingId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Booking ID copied!'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: Row(children: [
                      Text(widget.bookingId,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy,
                          size: 13, color: Colors.grey),
                    ]),
                  ),
                ]),
          ],
        ),
      ),
    );
  }

  Widget _importantNotes() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline,
                  color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 8),
              Text('Important Reminders',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800)),
            ]),
            const SizedBox(height: 10),
            _note('Arrive 10 mins before your appointment time'),
            _note('Carry a valid ID proof and this booking confirmation'),
            _note('Bring any prior prescriptions or test reports'),
            if (widget.visitType == 'Video Consult')
              _note(
                  'You will receive a video link 15 mins before the call'),
            _note('For cancellation, contact at least 2 hours prior'),
          ],
        ),
      ),
    );
  }

  Widget _note(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.amber)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                  Navigator.pushNamed(context, '/home');
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Home',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showPrintableTicket, // ✅ REAL TICKET DIALOG
                icon: const Icon(Icons.receipt_long, color: primary),
                label: const Text('View & Copy Ticket',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(
                      context, '/my-appointments');
                },
                icon: const Icon(Icons.calendar_month,
                    color: Colors.green),
                label: const Text('View My Appointments',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.green)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}