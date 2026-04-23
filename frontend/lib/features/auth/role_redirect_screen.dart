import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/services/api_service.dart';

class RoleRedirectScreen extends StatefulWidget {
  const RoleRedirectScreen({super.key});

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    await ApiService.fetchUserProfile();

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final email = prefs.getString('user_email') ?? '';

    if (!mounted) return;

    // ── PATIENT ──────────────────────────────
    if (role == 'patient') {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // ── DOCTOR ───────────────────────────────
    if (role == 'doctor') {
      final status = prefs.getString('doctor_status_$email');

      // Pehle se approved hai (purana doctor)
      if (status == 'approved') {
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
        return;
      }

      // Form submit ho chuka hai, approval pending hai
      if (status == 'pending') {
        Navigator.pushReplacementNamed(
            context, '/doctor-verification-pending');
        return;
      }

      // Bilkul naya doctor — verification form dikhao
      Navigator.pushReplacementNamed(context, '/doctor-verification');
      return;
    }

    // ── FALLBACK ─────────────────────────────
    Navigator.pushReplacementNamed(context, '/role');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}