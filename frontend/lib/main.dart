import 'package:ai_medical_app/features/auth/landing_page.dart';
import 'package:ai_medical_app/features/admin/admin_login_screen.dart';
import 'package:ai_medical_app/features/admin/admin_dashboard_screen.dart';

import 'package:flutter/material.dart';
import 'package:ai_medical_app/features/auth/forgot_password_screen.dart';
// ================= IMPORTS =================
import 'package:ai_medical_app/features/splash/splash_screen.dart';

import 'package:ai_medical_app/features/auth/auth_screen.dart';
import 'package:ai_medical_app/features/auth/role_selection_screen.dart';
import 'package:ai_medical_app/features/auth/role_redirect_screen.dart';

import 'package:ai_medical_app/features/home/home_screen.dart';
import 'package:ai_medical_app/features/home/settings_screen.dart';
import 'package:ai_medical_app/features/home/edit_profile_screen.dart';

import 'package:ai_medical_app/features/patient/doctors/doctor_list_screen.dart';
import 'package:ai_medical_app/features/patient/doctors/doctor_model.dart';
import 'package:ai_medical_app/features/patient/doctors/doctor_booking_screen.dart';
import 'package:ai_medical_app/features/patient/appointments/my_appointments_screen.dart';
import 'package:ai_medical_app/features/patient/reports/medical_reports_screen.dart';

import 'package:ai_medical_app/features/doctor/auth/doctor_verification_screen.dart';
import 'package:ai_medical_app/features/doctor/auth/doctor_verification_pending_screen.dart';
import 'package:ai_medical_app/features/doctor/dashboard/doctor_dashboard_screen.dart';

import 'package:ai_medical_app/features/chatbot/chatbot_screen.dart';
import 'package:ai_medical_app/features/health/screens/health_screen.dart';

import 'package:ai_medical_app/features/admin/admin_doctors_screen.dart';
import 'package:ai_medical_app/features/admin/admin_patients_screen.dart';
import 'package:ai_medical_app/features/admin/admin_requests_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medico AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9C89E8)),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9C89E8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C89E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingPage(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/role': (context) => const RoleSelectionScreen(),
        '/auth': (context) => const AuthScreen(),
        '/role-redirect': (context) => const RoleRedirectScreen(),
        '/home': (context) => const HomeScreen(),
        '/doctors': (context) => const DoctorListScreen(),
        '/book-appointment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Doctor;
          return DoctorBookingScreen(doctor: args);
        },
        '/my-appointments': (context) => const MyAppointmentsScreen(),
        '/medical-reports': (context) => const MedicalReportsScreen(),
        '/health-articles': (context) => const HealthScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/doctor-verification': (context) => const DoctorVerificationScreen(),
        '/doctor-verification-pending': (context) => const DoctorVerificationPendingScreen(),
        '/doctor-dashboard': (context) => const DoctorDashboardScreen(),
        '/doctor-patients': (context) => const DoctorListScreen(),
        '/approved-patients': (context) => const DoctorListScreen(),
        '/patient-records': (context) => const MedicalReportsScreen(),
        '/ai-summary': (context) => const ChatbotScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/symptom-chat': (context) => const ChatbotScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text("Route '${settings.name}' not found!"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}