import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'doctor_model.dart';
import 'booking_confirmation_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_medical_app/services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime appointmentDate;
  final String appointmentSlot;
  final String visitType;
  final String patientName;
  final String patientAge;
  final String patientPhone;
  final String reason;

  const PaymentScreen({
    super.key,
    required this.doctor,
    required this.appointmentDate,
    required this.appointmentSlot,
    required this.visitType,
    required this.patientName,
    required this.patientAge,
    required this.patientPhone,
    required this.reason,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color primary = Color(0xFF9C89E8);
  static const Color dark = Color(0xFF5E4DB2);
  static const Color light = Color(0xFFEDE7F6);

  // Test key — must match RAZORPAY_KEY_ID in your .env
  static const String _razorpayKey = 'rzp_test_SanR5bmdBRKLmI';

  late Razorpay _razorpay;
  late String _currentBookingId;

  String _paymentMethod = 'upi';
  bool _isProcessing = false;

  final _upiController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _selectedBank = 'SBI';
  String _selectedWallet = 'PhonePe';

  final List<String> _banks = [
    'SBI', 'HDFC', 'ICICI', 'Axis Bank', 'Kotak', 'PNB', 'Bank of Baroda'
  ];
  final List<String> _wallets = [
    'PhonePe', 'Paytm', 'Google Pay', 'Amazon Pay'
  ];

  late int _consultFee;
  late int _convenienceFee;
  late int _total;

  @override
  void initState() {
    super.initState();
    _consultFee = widget.doctor.fees;
    _convenienceFee = (_consultFee * 0.02).ceil().clamp(10, 50);
    _total = _consultFee + _convenienceFee;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // ─── Payment event handlers ────────────────────────────────────────
bool isTestMode = true;
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
  debugPrint('✅ Payment success: ${response.paymentId}');

  // 🧪 DUMMY MODE → skip backend verification
  if (isTestMode) {
    if (!mounted) return;

    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          doctor: widget.doctor,
          appointmentDate: widget.appointmentDate,
          appointmentSlot: widget.appointmentSlot,
          visitType: widget.visitType,
          patientName: widget.patientName,
          patientPhone: widget.patientPhone,
          bookingId: _currentBookingId,
          amountPaid: _total,
          paymentMethod: _paymentMethod,
        ),
      ),
    );
    return; // 🚨 VERY IMPORTANT
  }

  // 🔽 REAL PAYMENT FLOW (only when isTestMode = false)
  setState(() => _isProcessing = true);

  try {
    final verifyResponse = await http.post(
      Uri.parse("${ApiService.baseUrl}/payment/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "razorpay_order_id": response.orderId ?? '',
        "razorpay_payment_id": response.paymentId ?? '',
        "razorpay_signature": response.signature ?? '',
      }),
    );

    debugPrint('Verify status: ${verifyResponse.statusCode}');
    debugPrint('Verify body: ${verifyResponse.body}');

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (verifyResponse.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            doctor: widget.doctor,
            appointmentDate: widget.appointmentDate,
            appointmentSlot: widget.appointmentSlot,
            visitType: widget.visitType,
            patientName: widget.patientName,
            patientPhone: widget.patientPhone,
            bookingId: _currentBookingId,
            amountPaid: _total,
            paymentMethod: _paymentMethod,
          ),
        ),
      );
    } else {
      _showError("Payment verification failed. Please contact support.");
    }
  } catch (e) {
    debugPrint('Verify error: $e');
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showError("Network error during verification. Please try again.");
  }
}

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment error: ${response.code} — ${response.message}');
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showError('Payment failed: ${response.message ?? "Unknown error"}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('👜 External wallet: ${response.walletName}');
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  // ─── Validation ────────────────────────────────────────────────────

  bool _validatePaymentDetails() {
    if (_paymentMethod == 'upi') {
      final upi = _upiController.text.trim();
      if (!upi.contains('@') || upi.length < 5) {
        _showError('Enter a valid UPI ID (e.g. name@okaxis)');
        return false;
      }
    } else if (_paymentMethod == 'card') {
      final cardNum = _cardNumberController.text.replaceAll(' ', '');
      if (cardNum.length != 16) {
        _showError('Enter a valid 16-digit card number');
        return false;
      }
      if (_cardNameController.text.trim().isEmpty) {
        _showError('Enter the name on card');
        return false;
      }
      if (_expiryController.text.trim().length < 5) {
        _showError('Enter a valid expiry (MM/YY)');
        return false;
      }
      final parts = _expiryController.text.split('/');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 0;
        final year = int.tryParse('20${parts[1]}') ?? 0;
        final now = DateTime.now();
        if (month < 1 || month > 12) {
          _showError('Invalid expiry month');
          return false;
        }
        if (year < now.year || (year == now.year && month < now.month)) {
          _showError('Card has expired');
          return false;
        }
      }
      if (_cvvController.text.trim().length < 3) {
        _showError('Enter a valid 3-digit CVV');
        return false;
      }
    }
    return true;
  }

  // ─── Core payment flow ─────────────────────────────────────────────

Future<void> _processPayment() async {
  if (!_validatePaymentDetails()) return;

  setState(() => _isProcessing = true);

  // Generate booking ID
  _currentBookingId =
      'MED${DateTime.now().millisecondsSinceEpoch % 1000000}';

  try {
    // 🧪 DUMMY PAYMENT MODE (NO BACKEND, NO RAZORPAY)
    debugPrint('Running in DUMMY payment mode...');

    await Future.delayed(const Duration(seconds: 2));

    _handlePaymentSuccess(
      PaymentSuccessResponse(
        "pay_dummy_123",     // paymentId
        "order_dummy_123",   // orderId
        "signature_dummy",   // signature
        null,                // ✅ REQUIRED 4th parameter
      ),
    );

  } catch (e) {
    debugPrint('PAYMENT ERROR: $e');
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showError('Dummy payment failed: $e');
  }
}

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Secure Payment'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: const [
              Icon(Icons.lock, size: 16),
              SizedBox(width: 4),
              Text('SSL Secured', style: TextStyle(fontSize: 12)),
            ]),
          ),
        ],
      ),
      body: _isProcessing ? _processingOverlay() : _paymentBody(),
    );
  }

  Widget _processingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Opening Payment Gateway...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Please do not press back',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const Text('🔒 Powered by Razorpay',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _paymentBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Test-mode banner (remove in production) ────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade400),
            ),
            child: const Text(
              '🧪 TEST MODE  •  UPI: success@razorpay  •  Card: 4111 1111 1111 1111',
              style: TextStyle(fontSize: 11, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          _appointmentSummaryCard(),
          const SizedBox(height: 20),
          _paymentMethodSelector(),
          const SizedBox(height: 20),
          _paymentForm(),
          const SizedBox(height: 20),
          _trustBadges(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock),
                  const SizedBox(width: 10),
                  Text('Pay ₹$_total',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('100% Safe & Secure Payments',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _appointmentSummaryCard() {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_note, color: primary, size: 20),
            const SizedBox(width: 8),
            const Text('Appointment Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const Divider(height: 20),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: light,
              child: Text(widget.doctor.name[0].toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: dark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${widget.doctor.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.doctor.speciality,
                      style: const TextStyle(color: primary, fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _summaryTile(Icons.calendar_today,
              '${widget.appointmentDate.day} ${months[widget.appointmentDate.month]} ${widget.appointmentDate.year} at ${widget.appointmentSlot}'),
          _summaryTile(Icons.location_on, widget.visitType),
          _summaryTile(Icons.person, 'Patient: ${widget.patientName}'),
          const Divider(height: 20),
          _feeRow('Consultation Fee', '₹$_consultFee'),
          _feeRow('Convenience Fee', '₹$_convenienceFee', sub: 'Includes GST'),
          const Divider(height: 16),
          _feeRow('Total Amount', '₹$_total', bold: true, color: dark),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _feeRow(String label, String value,
      {bool bold = false, Color? color, String? sub}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: bold ? 15 : 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: color ?? Colors.black87,
                  )),
              if (sub != null)
                Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
              )),
        ],
      ),
    );
  }

  Widget _paymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          _methodChip('upi', 'UPI', Icons.account_balance_wallet),
          const SizedBox(width: 8),
          _methodChip('card', 'Card', Icons.credit_card),
          const SizedBox(width: 8),
          _methodChip('netbanking', 'Net Banking', Icons.account_balance),
          const SizedBox(width: 8),
          _methodChip('wallet', 'Wallet', Icons.wallet),
        ]),
      ],
    );
  }

  Widget _methodChip(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? primary : Colors.grey.shade300),
          ),
          child: Column(children: [
            Icon(icon, size: 20, color: selected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _paymentForm() {
    switch (_paymentMethod) {
      case 'upi':
        return _upiForm();
      case 'card':
        return _cardForm();
      case 'netbanking':
        return _netbankingForm();
      case 'wallet':
        return _walletForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _upiForm() {
    return _formCard(
      title: 'Enter UPI ID',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(children: [
        _inputField(
          controller: _upiController,
          // ← Use this test UPI ID for dummy payments in test mode
          hint: 'success@razorpay  (test) or yourname@okaxis',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        const Text(
          'Test UPI IDs: success@razorpay (success) · failure@razorpay (fail)',
          style: TextStyle(fontSize: 11, color: Colors.green),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _upiAppBadge('GPay', Colors.blue),
            _upiAppBadge('PhonePe', const Color(0xFF5F259F)),
            _upiAppBadge('Paytm', Colors.indigo),
            _upiAppBadge('BHIM', Colors.orange),
          ],
        ),
      ]),
    );
  }

  Widget _upiAppBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(name,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _cardForm() {
    return _formCard(
      title: 'Card Details',
      icon: Icons.credit_card,
      child: Column(children: [
        _inputField(
          controller: _cardNumberController,
          hint: '4111 1111 1111 1111  (test card)',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19,
        ),
        const SizedBox(height: 12),
        _inputField(controller: _cardNameController, hint: 'Name on Card'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _inputField(
              controller: _expiryController,
              hint: 'MM/YY',
              keyboardType: TextInputType.number,
              inputFormatters: [_ExpiryFormatter()],
              maxLength: 5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _inputField(
              controller: _cvvController,
              hint: 'CVV',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              obscureText: true,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.info_outline, size: 13, color: Colors.green),
          const SizedBox(width: 6),
          const Text('Test: 4111 1111 1111 1111  •  Any future MM/YY  •  Any CVV',
              style: TextStyle(fontSize: 11, color: Colors.green)),
        ]),
      ]),
    );
  }

  Widget _netbankingForm() {
    return _formCard(
      title: 'Select Your Bank',
      icon: Icons.account_balance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._banks.map((bank) => RadioListTile<String>(
                value: bank,
                groupValue: _selectedBank,
                title: Text(bank),
                activeColor: primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (v) => setState(() => _selectedBank = v!),
              )),
          const SizedBox(height: 8),
          const Text('You will be redirected to your bank\'s secure portal.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _walletForm() {
    return _formCard(
      title: 'Select Wallet',
      icon: Icons.wallet,
      child: Column(
        children: _wallets
            .map((wallet) => RadioListTile<String>(
                  value: wallet,
                  groupValue: _selectedWallet,
                  title: Text(wallet),
                  activeColor: primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (v) => setState(() => _selectedWallet = v!),
                ))
            .toList(),
      ),
    );
  }

  Widget _formCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _trustBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _badge(Icons.lock, '256-bit\nEncryption'),
        _badge(Icons.verified_user, 'PCI DSS\nCompliant'),
        _badge(Icons.security, 'Powered by\nRazorpay'),
      ],
    );
  }

  Widget _badge(IconData icon, String text) {
    return Column(children: [
      Icon(icon, size: 22, color: Colors.green),
      const SizedBox(height: 4),
      Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}

// ─── Input formatters ──────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
        text: str,
        selection: TextSelection.collapsed(offset: str.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length >= 2) {
      final str = '${digits.substring(0, 2)}/${digits.substring(2)}';
      return TextEditingValue(
          text: str,
          selection: TextSelection.collapsed(offset: str.length));
    }
    return newValue;
  }
}