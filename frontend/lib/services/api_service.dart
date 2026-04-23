import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiService {
  static String _getHost() {
    if (Platform.isAndroid) {
      return "10.0.2.2";       // Android emulator always uses this to reach localhost
    } else if (Platform.isIOS) {
      return "127.0.0.1";      // iOS simulator uses localhost directly
    } else {
      return "127.0.0.1";      // Web/desktop
    }
  }

  // ✅ Root URL for the main backend (used for file fetching)
  static String get mainBaseUrl {
    return "http://${_getHost()}:8000";
  }

  static String get baseUrl {
    return "http://${_getHost()}:8000/api/v1";   // Main backend
  }

  static String get doctorBotUrl {
    return "http://${_getHost()}:8001";          // Doctor bot
  }

  static String get aiBotUrl {
    return "http://${_getHost()}:8002";          // AI bot (medibot)
  }

  // ── Token Helpers ────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // ── Auth ─────────────────────────────────────────────────────────
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": email, "password": password},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> signup(String email, String password, String name) async {
    return signupWithRole(email, password, name, 'patient');
  }

  static Future<bool> signupWithRole(
      String email, String password, String name, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "full_name": name,
          "role": role,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ── Forgot Password ─────────────────────────────────────────────
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email, "otp": otp},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": email, "new_password": newPassword},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Fetch User Profile ───────────────────────────────────────────
  static Future<bool> fetchUserProfile() async {
    try {
      final headers = await _authHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_name', data['full_name'] ?? 'User');
        await prefs.setString('user_email', data['email'] ?? '');
        await prefs.setString('user_role', data['role'] ?? 'patient');
        await prefs.setInt('user_id', data['id'] ?? 0);
        final isVerified = data['is_verified'] ?? false;
        final email = data['email'] ?? '';
        if (isVerified == true) {
          await prefs.setString('doctor_status_$email', 'approved');
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Doctor Verify ────────────────────────────────────────────────
  static Future<void> verifyDoctor() async {
    try {
      final headers = await _authHeaders();
      await http.post(Uri.parse('$baseUrl/access/verify-doctor'),
          headers: headers);
    } catch (e) {}
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('patient_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('doctor_status');
  }

  // ── Medical Records ──────────────────────────────────────────────
  static Future<bool> uploadMedicalRecord(PlatformFile file) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final uri = Uri.parse('$baseUrl/records/');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = file.name;
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'file', file.bytes!,
            filename: file.name));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', file.path!));
      }
      final res = await request.send();
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyRecords() async {
    try {
      final headers = await _authHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/records/'), headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteMedicalRecord(int recordId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
          Uri.parse('$baseUrl/records/$recordId'),
          headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ── Doctor Endpoints ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchAllPatients() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/doctor/patients'),
          headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Get Profile ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile(int userId) async {
    final headers = await _authHeaders();
    final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ── ACCESS REQUEST SYSTEM ────────────────────────────────────────
  static Future<Map<String, dynamic>?> sendAccessRequest(int patientId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/access/request'),
        headers: headers,
        body: jsonEncode({"patient_id": patientId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> cancelAccessRequest(int patientId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/access/cancel-request/$patientId'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyAccessRequests() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/access/my-requests'),
          headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> respondToAccessRequest(
      int requestId, String action) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/access/respond/$requestId?action=$action'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchApprovedPatients() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/access/approved-patients'),
          headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPatientRecords(
      int patientId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/access/patient-records/$patientId'),
          headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String> getAccessStatus(int patientId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/access/status/$patientId'),
          headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['status'] ?? 'not_requested';
      }
      return 'not_requested';
    } catch (e) {
      return 'not_requested';
    }
  }

  static Future<int> getNotificationCount() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/access/notification-count'),
          headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ── User Helpers ─────────────────────────────────────────────────
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/profile/update-profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Doctor Verification ──────────────────────────────────────────
  static Future<bool> submitDoctorVerification({
    required String name,
    required String degree,
    required String speciality,
    required String hospital,
    required String regNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    await prefs.setString('doctor_name', name);
    await prefs.setString('doctor_degree', degree);
    await prefs.setString('doctor_speciality', speciality);
    await prefs.setString('doctor_hospital', hospital);
    await prefs.setString('doctor_reg_no', regNo);
    await prefs.setString('doctor_status_$email', 'pending');
    return true;
  }

  // ── Admin ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchAdminStats() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/admin/stats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ── Doctor Recommendations ───────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getDoctors({
    required String location,
    required double maxDistance,
    required int maxFees,
    required double minRating,
    required String specialization,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/recommend'),
        headers: headers,
        body: jsonEncode({
          "location": "$location, Delhi",
          "max_distance": maxDistance,
          "max_fees": maxFees,
          "min_rating": minRating,
          "specialization": specialization,
        }),
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Appointments ─────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchMyAppointments() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/appointments/my'),
          headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUpcomingAppointments() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
          Uri.parse('$baseUrl/appointments/upcoming'),
          headers: headers);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> cancelAppointment(int appointmentId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
          Uri.parse('$baseUrl/appointments/$appointmentId'),
          headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> bookAppointment({
    required String doctorName,
    required String doctorRegNo,
    required String doctorSpeciality,
    required String appointmentDate,
    required String appointmentSlot,
    required String visitType,
    required String patientName,
    required String patientPhone,
    required String reason,
    required int amountPaid,
    required String paymentMethod,
    required String bookingId,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/book'),
        headers: headers,
        body: jsonEncode({
          "doctor_name": doctorName,
          "doctor_reg_no": doctorRegNo,
          "doctor_speciality": doctorSpeciality,
          "appointment_date": appointmentDate,
          "appointment_slot": appointmentSlot,
          "visit_type": visitType,
          "patient_name": patientName,
          "patient_phone": patientPhone,
          "reason": reason,
          "amount_paid": amountPaid,
          "payment_method": paymentMethod,
          "booking_id": bookingId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> fetchBookedSlots({
    required String doctorName,
    required String date,
  }) async {
    try {
      final headers = await _authHeaders();
      final encodedName = Uri.encodeComponent(doctorName);
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/slots/$encodedName/$date'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['booked_slots'] as List).cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Prescriptions (Patient) ───────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchMyPrescriptions() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/prescriptions/my-prescriptions'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPrescriptionsForPatient(
      int patientId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/prescriptions/patient/$patientId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> uploadPrescription({
    required int patientId,
    required String title,
    String? notes,
    PlatformFile? file,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final uri = Uri.parse('$baseUrl/prescriptions/');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['patient_id'] = patientId.toString();
      request.fields['title'] = title;
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      if (file != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
              'file', file.bytes!,
              filename: file.name));
        } else {
          request.files
              .add(await http.MultipartFile.fromPath('file', file.path!));
        }
      }

      final res = await request.send();
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}