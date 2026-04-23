import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/services/api_service.dart';

class DoctorVerificationPendingScreen extends StatelessWidget {
  const DoctorVerificationPendingScreen({super.key});

  Future<void> _approveDoctor(BuildContext context) async {
    // ✅ Backend mein verified mark karo
    await ApiService.verifyDoctor();

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    await prefs.setString('doctor_status_$email', 'approved');

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/doctor-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        title: const Text("Verification Pending"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Your profile is under verification",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Our team is reviewing your medical credentials.\n"
              "You will be notified once approved.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text(
                "✅ Approve (Dev Only)",
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _approveDoctor(context),
            ),
          ],
        ),
      ),
    );
  }
}