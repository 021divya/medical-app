import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/services/api_service.dart';
import '../records/doctor_patient_records_screen.dart';
import '../../ai/ai_summarization_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  String doctorName = '';
  String doctorSpeciality = '';

  bool _loadingAll = true;
  List<Map<String, dynamic>> _allPatients = [];

  bool _loadingApproved = true;
  List<Map<String, dynamic>> _approvedPatients = [];

  // Tracks request status per patient: 'pending' | 'approved'
  final Map<int, String> _requestStatus = {};

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    _fetchAllPatients();
    _fetchApprovedPatients();
  }

  Future<void> _loadDoctorInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName =
          prefs.getString('doctor_name') ??
          prefs.getString('patient_name') ??
          'Doctor';
      doctorSpeciality = prefs.getString('doctor_speciality') ?? 'Specialist';
    });
  }

  Future<void> _fetchAllPatients() async {
    setState(() => _loadingAll = true);
    final data = await ApiService.fetchAllPatients();
    if (!mounted) return;

    // Fetch status for each patient
    final Map<int, String> statuses = {};
    for (final p in data) {
      final id = p['id'] as int;
      final status = await ApiService.getAccessStatus(id);
      if (status == 'pending' || status == 'approved') {
        statuses[id] = status;
      }
    }

    setState(() {
      _allPatients = data;
      _loadingAll = false;
      _requestStatus.addAll(statuses);
    });
  }

  Future<void> _fetchApprovedPatients() async {
    setState(() => _loadingApproved = true);
    final data = await ApiService.fetchApprovedPatients();
    if (!mounted) return;
    setState(() {
      _approvedPatients = data;
      _loadingApproved = false;
    });
  }

  
  Future<void> _sendRequest(Map<String, dynamic> patient) async {
    final patientId = patient['id'] as int;
    final patientName = patient['full_name'] ?? patient['name'] ?? 'Patient';

    final currentStatus = _requestStatus[patientId];

    if (currentStatus == 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $patientName already approved you!")),
      );
      return;
    }

    if (currentStatus == 'pending') {
      await _cancelRequest(patient);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Send Access Request"),
        content: Text(
            "Send a request to $patientName to access their medical records?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C89E8)),
            child: const Text("Send Request"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    
    setState(() => _requestStatus[patientId] = 'pending');

    final result = await ApiService.sendAccessRequest(patientId);
    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Request sent to $patientName!")),
      );
      _fetchApprovedPatients();
    } else {
      
      setState(() => _requestStatus.remove(patientId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to send request.")),
      );
    }
  }

  
  Future<void> _cancelRequest(Map<String, dynamic> patient) async {
    final patientId = patient['id'] as int;
    final patientName = patient['full_name'] ?? patient['name'] ?? 'Patient';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Request"),
        content: Text(
            "Do you want to cancel the access request sent to $patientName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Request"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Cancel Request"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    
    setState(() => _requestStatus.remove(patientId));

    final result = await ApiService.cancelAccessRequest(patientId);
    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🗑️ Request to $patientName cancelled.")),
      );
    } else {
      
      setState(() => _requestStatus[patientId] = 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to cancel request.")),
      );
    }
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        title: const Text("Doctor Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: "Logout"),
        ],
      ),

      drawer: _buildDrawer(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGreetingCard(),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [

                  _dashboardBox(
                    title: "All Patients",
                    icon: Icons.people,
                    color: const Color(0xFF9C89E8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text("All Patients")),
                            body: _allPatientsTab(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _dashboardBox(
                    title: "AI Medical Summary",
                    icon: Icons.auto_awesome,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AISummarizationScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  _dashboardBox(
                    title: "View Patients Records",
                    icon: Icons.lock_open,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                                title: const Text("Approved Patients")),
                            body: _approvedPatientsTab(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C89E8), Color(0xFF7E6AD6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.medical_services, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. $doctorName",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                Text(
                  doctorSpeciality,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            tooltip: "AI Summary",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AISummarizationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardBox({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }

  Widget _allPatientsTab() {
    if (_loadingAll) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allPatients.isEmpty) {
      return const Center(child: Text("No patients found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allPatients.length,
      itemBuilder: (_, i) => _allPatientTile(_allPatients[i]),
    );
  }

 
  Widget _allPatientTile(Map<String, dynamic> patient) {
    final name = patient['full_name'] ?? patient['name'] ?? 'Patient';
    final email = patient['email'] ?? '';
    final patientId = patient['id'] as int;
    final status = _requestStatus[patientId];

    Widget trailingButton;
    if (status == 'approved') {
      trailingButton = ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text("Approved", style: TextStyle(color: Colors.white)),
      );
    } else if (status == 'pending') {
     
      trailingButton = ElevatedButton(
        onPressed: () => _cancelRequest(patient),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text("Requested ✕",
            style: TextStyle(color: Colors.white)),
      );
    } else {
      trailingButton = ElevatedButton(
        onPressed: () => _sendRequest(patient),
        child: const Text("Request"),
      );
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name[0].toUpperCase()),
        ),
        title: Text(name),
        subtitle: Text(email),
        trailing: trailingButton,
      ),
    );
  }

  Widget _approvedPatientsTab() {
    if (_loadingApproved) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_approvedPatients.isEmpty) {
      return const Center(child: Text("No approved patients yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvedPatients.length,
      itemBuilder: (_, i) => _approvedPatientTile(_approvedPatients[i]),
    );
  }

  Widget _approvedPatientTile(Map<String, dynamic> patient) {
    final name = patient['patient_name'] ?? 'Patient';
    final patientId = patient['patient_id'] as int;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(name),
        trailing: ElevatedButton(
          child: const Text("View Records"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorPatientRecordsScreen(
                  patientId: patientId,
                  patientName: name,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF5E4DB2),
        child: SafeArea(
          child: ListView(
            children: [
              const SizedBox(height: 40),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.white),
                title: const Text("Dashboard",
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading:
                    const Icon(Icons.auto_awesome, color: Colors.white),
                title: const Text("AI Summarization",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AISummarizationScreen()));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text("Logout",
                    style: TextStyle(color: Colors.redAccent)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



