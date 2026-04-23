import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'doctor_model.dart';
import 'payment_screen.dart';

class DoctorBookingScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorBookingScreen({super.key, required this.doctor});

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  static const Color primary = Color(0xFF9C89E8);
  static const Color dark = Color(0xFF5E4DB2);
  static const Color light = Color(0xFFEDE7F6);

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;
  String _visitType = 'In-Clinic';

  final _nameController   = TextEditingController();
  final _ageController    = TextEditingController();
  final _phoneController  = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _morningSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM',
    '10:30 AM', '11:00 AM', '11:30 AM',
  ];
  final List<String> _eveningSlots = [
    '05:00 PM', '05:30 PM', '06:00 PM',
    '06:30 PM', '07:00 PM', '07:30 PM',
  ];

  Set<String> _bookedSlots = {};
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookedSlots() async {
    setState(() => _loadingSlots = true);
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final slots = await ApiService.fetchBookedSlots(
      doctorName: widget.doctor.name,
      date: dateStr,
    );
    if (!mounted) return;
    setState(() {
      _bookedSlots = slots.toSet();
      _loadingSlots = false;
      if (_selectedSlot != null && _bookedSlots.contains(_selectedSlot)) {
        _selectedSlot = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; _selectedSlot = null; });
      _fetchBookedSlots();
    }
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Please select a time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          doctor: widget.doctor,
          appointmentDate: _selectedDate,
          appointmentSlot: _selectedSlot!,
          visitType: _visitType,
          patientName: _nameController.text.trim(),
          patientAge: _ageController.text.trim(),
          patientPhone: _phoneController.text.trim(),
          reason: _reasonController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Book Appointment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _doctorCard(),
              const SizedBox(height: 20),
              _visitTypeSelector(),
              const SizedBox(height: 20),
              _datePicker(),
              const SizedBox(height: 20),
              if (_loadingSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Checking available slots...',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else ...[
                _slotSection('🌅 Morning Slots', _morningSlots),
                const SizedBox(height: 16),
                _slotSection('🌆 Evening Slots', _eveningSlots),
              ],
              const SizedBox(height: 20),
              _patientDetailsForm(),
              const SizedBox(height: 24),
              _bookingSummary(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment),
                      SizedBox(width: 10),
                      Text('Proceed to Payment',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doctorCard() {
    final d = widget.doctor;
    final regNo = 'MCI-${d.name.hashCode.abs() % 90000 + 10000}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: light,
          child: Text(d.name[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: dark)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. ${d.name}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text(d.speciality,
                style: const TextStyle(color: primary, fontSize: 13)),
            Row(children: [
              const Icon(Icons.verified, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text('Reg: $regNo',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            Row(children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${d.rating} • ${d.experience} yrs exp',
                  style: const TextStyle(fontSize: 12)),
            ]),
          ]),
        ),
        Column(children: [
          Text('₹${d.fees}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
          const Text('fee',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _visitTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Visit Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Row(
          children: ['In-Clinic', 'Video Consult'].map((type) {
            final selected = _visitType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _visitType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: type == 'In-Clinic' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? primary : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'In-Clinic'
                            ? Icons.local_hospital
                            : Icons.videocam,
                        color: selected ? Colors.white : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(type,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _datePicker() {
    final days =
        List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month, size: 16, color: primary),
              label: const Text('Full Calendar',
                  style: TextStyle(color: primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (_, i) {
              final d = days[i];
              final selected = d.day == _selectedDate.day &&
                  d.month == _selectedDate.month;
              const dayLabels = [
                'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
              ];
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedDate = d; _selectedSlot = null; });
                  _fetchBookedSlots();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  width: 52,
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? primary : Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayLabels[d.weekday - 1],
                          style: TextStyle(
                              fontSize: 11,
                              color: selected ? Colors.white70 : Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${d.day}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _slotSection(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final booked = _bookedSlots.contains(slot);
            final selected = _selectedSlot == slot;
            return GestureDetector(
              onTap: booked ? null : () => setState(() => _selectedSlot = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: booked
                      ? Colors.grey.shade100
                      : selected
                          ? primary
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: booked
                        ? Colors.grey.shade300
                        : selected
                            ? primary
                            : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  booked ? '$slot\n(Booked)' : slot,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: booked
                        ? Colors.grey
                        : selected
                            ? Colors.white
                            : Colors.black87,
                    decoration:
                        booked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _patientDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),

          // ── Full Name ─────────────────────────────────────────
          _validatedField(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person,
            keyboardType: TextInputType.name,
            // ✅ Only letters and spaces allowed
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) return 'Enter a valid name';
              return null;
            },
          ),
          const SizedBox(height: 12),

          Row(children: [
            // ── Age ───────────────────────────────────────────
            Expanded(
              child: _validatedField(
                controller: _ageController,
                hint: 'Age',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                // ✅ Only digits, max 3 chars
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final age = int.tryParse(v);
                  if (age == null) return 'Invalid';
                  if (age < 1 || age > 120) return '1–120 only';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),

            // ── Phone ─────────────────────────────────────────
            Expanded(
              child: _validatedField(
                controller: _phoneController,
                hint: 'Phone (10 digits)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                // ✅ Only digits, exactly 10
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length != 10) return 'Must be 10 digits';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Reason (optional, no special validation) ─────────
          _validatedField(
            controller: _reasonController,
            hint: 'Reason for Visit (optional)',
            icon: Icons.medical_services,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _validatedField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ Live validation
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _bookingSummary() {
    if (_selectedSlot == null) return const SizedBox.shrink();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: light,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Summary',
              style: TextStyle(fontWeight: FontWeight.bold, color: dark)),
          const SizedBox(height: 10),
          _summaryRow(Icons.calendar_today,
              '${_selectedDate.day} ${months[_selectedDate.month]} ${_selectedDate.year}'),
          _summaryRow(Icons.access_time, _selectedSlot!),
          _summaryRow(Icons.location_on, _visitType),
          const Divider(height: 16),
          _summaryRow(Icons.currency_rupee,
              '${widget.doctor.fees}  (Consultation Fee)',
              bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 15, color: dark),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? dark : Colors.black87,
            )),
      ]),
    );
  }
}