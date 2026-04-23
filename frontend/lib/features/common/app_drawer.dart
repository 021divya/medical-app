import 'package:flutter/material.dart';
import 'package:ai_medical_app/services/api_service.dart';
import 'package:ai_medical_app/features/home/settings_screen.dart';
import 'package:ai_medical_app/features/home/edit_profile_screen.dart';
import 'package:ai_medical_app/features/home/my_prescriptions_screen.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.userName,
    required this.currentRoute,
  });

  static const Color primary = Color(0xFF9C89E8);
  static const Color dark = Color(0xFF5E4DB2);

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/role');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: dark,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              _sectionTitle("CORE FEATURES"),
              _drawerItem(context,
                  icon: Icons.smart_toy_outlined,
                  title: "AI Symptom Checker",
                  route: '/chatbot'),
              _drawerItem(context,
                  icon: Icons.search,
                  title: "Find Doctors",
                  route: '/doctors'),
              _drawerItem(context,
                  icon: Icons.description_outlined,
                  title: "Medical Reports",
                  route: '/medical-reports'),
              _drawerItem(context,
                  icon: Icons.medication_outlined,
                  title: "My Prescriptions",
                  route: '/prescriptions'),
              const Divider(color: Colors.white24),
              _sectionTitle("ESSENTIALS"),
              _drawerItem(context,
                  icon: Icons.menu_book_outlined,
                  title: "Read About Health",
                  route: '/health-articles'),
              _drawerItem(context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  route: '/settings'),
              const Divider(color: Colors.white30),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7E6AD6), Color(0xFF5E4DB2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : "U",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            child: const Text(
              "View & Edit Profile",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isActive = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isActive) {
          if (route == '/settings') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          } else if (route == '/prescriptions') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const MyPrescriptionsScreen()),
            );
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
    );
  }
}