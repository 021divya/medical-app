import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class HealthService {
  static String get _host {
    if (Platform.isAndroid) return "10.0.2.2";
    if (Platform.isIOS) return "127.0.0.1";
    return "127.0.0.1";
  }

  // ✅ FIXED: matches app.include_router(health_router, prefix="/api")
  // Full URL becomes: http://10.0.2.2:8000/api/health-content
  static String get _baseUrl => "http://$_host:8000/api";

  static Future<List<dynamic>> fetchHealthContent() async {
    try {
      final url = Uri.parse('$_baseUrl/health-content');
      print("📡 Fetching: $url");

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      print("📥 Status: ${response.statusCode}");
      print("📥 Body preview: ${response.body.substring(0, response.body.length.clamp(0, 300))}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("❌ HealthService error: $e");
      return [];
    }
  }
}