import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Timer(const Duration(seconds: 3), _checkSession);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('user_role');

    if (token != null && token.isNotEmpty && role != null) {
      if (role == 'patient') {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (role == 'doctor') {
        final email = prefs.getString('user_email') ?? '';
        final status = prefs.getString('doctor_status_$email');
        if (status == 'approved') {
          Navigator.pushReplacementNamed(context, '/doctor-dashboard');
        } else if (status == 'pending') {
          Navigator.pushReplacementNamed(context, '/doctor-verification-pending');
        } else {
          Navigator.pushReplacementNamed(context, '/doctor-verification');
        }
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/landing');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB39DDB), Color(0xFF9C89E8), Color(0xFF7E6AD6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Spacer(),
              Icon(Icons.local_hospital, size: 72, color: Colors.white),
              SizedBox(height: 20),
              Text(
                "Medico AI",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Your AI-powered medical assistant\nfor better health every day",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
