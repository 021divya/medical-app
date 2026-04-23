import 'package:flutter/material.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'package:ai_medical_app/features/admin/admin_doctors_screen.dart';
import 'package:ai_medical_app/features/admin/admin_patients_screen.dart';
import 'package:ai_medical_app/features/admin/admin_requests_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _totalDoctors = 0;
  int _totalPatients = 0;
  int _totalRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await ApiService.fetchAdminStats();
    if (!mounted) return;
    setState(() {
      _totalDoctors = stats['total_doctors'] ?? 0;
      _totalPatients = stats['total_patients'] ?? 0;
      _totalRequests = stats['total_requests'] ?? 0;
      _isLoading = false;
    });
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 22),
            SizedBox(width: 8),
            Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: "Logout"),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome
                    const Text("Welcome, Admin 👋",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e))),
                    const SizedBox(height: 4),
                    Text("Tap a card to view details",
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 28),

                    // Clickable Cards
                    _statCard(
                      title: "Total Doctors",
                      value: _totalDoctors,
                      icon: Icons.medical_services,
                      color: const Color(0xFFE53935),
                      subtitle: "Tap to view all doctors",
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminDoctorsScreen())),
                    ),
                    const SizedBox(height: 16),

                    _statCard(
                      title: "Total Patients",
                      value: _totalPatients,
                      icon: Icons.people,
                      color: const Color(0xFFFF8F00),
                      subtitle: "Tap to view all patients",
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminPatientsScreen())),
                    ),
                    const SizedBox(height: 16),

                    _statCard(
                      title: "Access Requests",
                      value: _totalRequests,
                      icon: Icons.swap_horiz,
                      color: const Color(0xFF1565C0),
                      subtitle: "Tap to view all requests",
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminRequestsScreen())),
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: Text("Medico AI • Admin Panel",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}
