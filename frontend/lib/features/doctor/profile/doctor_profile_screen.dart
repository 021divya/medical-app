








import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String name = '';
  String degree = '';
  String speciality = '';
  String hospital = '';
  String regNo = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('doctor_name') ?? '-';
      degree = prefs.getString('doctor_degree') ?? '-';
      speciality = prefs.getString('doctor_speciality') ?? '-';
      hospital = prefs.getString('doctor_hospital') ?? '-';
      regNo = prefs.getString('doctor_reg_no') ?? '-';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _header(),
            const SizedBox(height: 20),
            _infoTile("Full Name", name, Icons.person),
            _infoTile("Degree", degree, Icons.school),
            _infoTile("Speciality", speciality, Icons.medical_services),
            _infoTile("Hospital / Clinic", hospital, Icons.local_hospital),
            _infoTile("Registration No.", regNo, Icons.badge),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            SizedBox(height: 12),
            Text(
              "Doctor Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Verified Medical Professional",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
