import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorVerificationScreen extends StatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  State<DoctorVerificationScreen> createState() =>
      _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _degreeController = TextEditingController();
  final _specialityController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _regNoController = TextEditingController();
  bool _isLoading = false;

  static const Color primary = Color(0xFF9C89E8);

  // Valid medical degrees
  final List<String> _validDegrees = [
    'MBBS', 'MD', 'MS', 'BDS', 'MDS', 'BAMS', 'BHMS', 'DNB',
    'DM', 'MCh', 'FRCS', 'MRCP', 'PhD', 'FCPS',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _degreeController.dispose();
    _specialityController.dispose();
    _hospitalController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';

    await prefs.setString('doctor_name', _nameController.text.trim());
    await prefs.setString('doctor_degree', _degreeController.text.trim().toUpperCase());
    await prefs.setString('doctor_speciality', _specialityController.text.trim());
    await prefs.setString('doctor_hospital', _hospitalController.text.trim());
    await prefs.setString('doctor_reg_no', _regNoController.text.trim().toUpperCase());
    await prefs.setString('doctor_status_$email', 'pending');

    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/doctor-verification-pending');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text("Doctor Verification"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF9C89E8)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please fill your medical credentials accurately for verification.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildField(
                _nameController,
                "Full Name",
                Icons.person,
                hint: "e.g. Dr. Rahul Sharma",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Full name is required";
                  }
                  if (value.trim().length < 3) {
                    return "Name must be at least 3 characters";
                  }
                  if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(value.trim())) {
                    return "Name can only contain letters and spaces";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Medical Degree
              _buildField(
                _degreeController,
                "Medical Degree",
                Icons.school,
                hint: "e.g. MBBS, MD, MS, BDS",
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Medical degree is required";
                  }
                  final upper = value.trim().toUpperCase();
                  final isValid = _validDegrees.any(
                    (d) => upper.contains(d),
                  );
                  if (!isValid) {
                    return "Enter a valid degree (MBBS, MD, MS, BDS, etc.)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Speciality
              _buildField(
                _specialityController,
                "Speciality",
                Icons.medical_services,
                hint: "e.g. Cardiologist, Dermatologist",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Speciality is required";
                  }
                  if (value.trim().length < 3) {
                    return "Enter a valid speciality";
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                    return "Speciality can only contain letters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Hospital
              _buildField(
                _hospitalController,
                "Hospital / Clinic Name",
                Icons.local_hospital,
                hint: "e.g. AIIMS Delhi, City Hospital",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Hospital/Clinic name is required";
                  }
                  if (value.trim().length < 3) {
                    return "Enter a valid hospital name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Registration Number
              _buildField(
                _regNoController,
                "Registration Number",
                Icons.badge,
                hint: "e.g. MCI-12345 or DL-67890",
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Registration number is required";
                  }
                  if (value.trim().length < 4) {
                    return "Enter a valid registration number";
                  }
                  if (!RegExp(r'^[A-Z0-9\-\/]+$')
                      .hasMatch(value.trim().toUpperCase())) {
                    return "Only letters, numbers, - and / allowed";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit for Verification",
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool obscure = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        prefixIcon: Icon(icon, color: primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9C89E8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator ??
          (value) => value == null || value.trim().isEmpty
              ? "This field is required"
              : null,
    );
  }
}

// Auto uppercase formatter
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
