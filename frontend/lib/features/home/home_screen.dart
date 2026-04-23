import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/services/api_service.dart';
import '../common/app_drawer.dart';
import '../patient/access/patient_access_requests_screen.dart';
import '../patient/appointments/my_appointments_screen.dart';
import 'my_prescriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String name = 'Guest User';
  int _notificationCount = 0;
  int _upcomingAppointmentCount = 0;

  static const Color primary     = Color(0xFF9C89E8);
  static const Color medicalBlue = Color(0xFF6C8EF5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => name = prefs.getString('patient_name') ?? 'Guest User');

    final count = await ApiService.getNotificationCount();
    if (!mounted) return;
    setState(() => _notificationCount = count);

    final appointments = await ApiService.fetchUpcomingAppointments();
    if (!mounted) return;
    setState(() => _upcomingAppointmentCount = appointments.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text("Medico AI",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: "Access Requests",
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const PatientAccessRequestsScreen()));
                  _loadData();
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 16),
                    child: Text('$_notificationCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(userName: name, currentRoute: '/home'),
      body: Stack(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, medicalBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text("Hello, $name 👋",
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 30),
                  _buildNotificationCard(),
                  const SizedBox(height: 14),
                  if (_upcomingAppointmentCount > 0) ...[
                    _buildAppointmentBanner(),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 16),
                  const Text("Quick Access",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildGrid(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentBanner() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()));
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.green.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.event_available, color: Colors.green.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_upcomingAppointmentCount Upcoming Appointment'
                    '${_upcomingAppointmentCount > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800),
                  ),
                  const Text('Tap to view details',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$_upcomingAppointmentCount',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PatientAccessRequestsScreen()));
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
          border: _notificationCount > 0
              ? Border.all(color: Colors.orange.shade200, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _notificationCount > 0
                    ? Colors.orange.shade50
                    : const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _notificationCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_none,
                color: _notificationCount > 0 ? Colors.orange : primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _notificationCount > 0
                        ? "$_notificationCount Doctor Access Request"
                            "${_notificationCount > 1 ? 's' : ''}"
                        : "No Pending Requests",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _notificationCount > 0
                          ? Colors.orange.shade800
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    _notificationCount > 0
                        ? "Tap to approve or reject"
                        : "All requests handled ✅",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_notificationCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$_notificationCount',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final items = [
      {
        'title': 'AI Symptom\nChecker',
        'icon': Icons.smart_toy_outlined,
        'color': primary,
        'route': '/chatbot',
        'badge': 0,
      },
      {
        'title': 'Find\nDoctors',
        'icon': Icons.search,
        'color': medicalBlue,
        'route': '/doctors',
        'badge': 0,
      },
      {
        'title': 'My\nAppointments',
        'icon': Icons.calendar_month,
        'color': const Color(0xFF43A047),
        'route': '/my-appointments',
        'badge': _upcomingAppointmentCount,
      },
      {
        'title': 'Medical\nReports',
        'icon': Icons.description_outlined,
        'color': const Color(0xFF4ECDC4),
        'route': '/medical-reports',
        'badge': 0,
      },
      {
        'title': 'My\nPrescriptions',      // ← NEW
        'icon': Icons.medication_outlined,
        'color': const Color(0xFF9C89E8),
        'route': '/prescriptions',
        'badge': 0,
      },
      {
        'title': 'Access\nRequests',
        'icon': Icons.lock_open,
        'color': Colors.orange,
        'route': null,
        'badge': _notificationCount,
      },
      {
        'title': 'Health\nModules',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFFFF6B6B),
        'route': '/health-articles',
        'badge': 0,
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_outlined,
        'color': const Color(0xFF95A5A6),
        'route': '/settings',
        'badge': 0,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.3),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item  = items[i];
        final badge = item['badge'] as int;

        return GestureDetector(
          onTap: () async {
            final route = item['route'];
            final title = item['title'] as String;

            if (title == 'Access\nRequests') {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const PatientAccessRequestsScreen()));
              _loadData();
            } else if (title == 'My\nAppointments') {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyAppointmentsScreen()));
              _loadData();
            } else if (title == 'My\nPrescriptions') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MyPrescriptionsScreen()));
            } else if (route != null) {
              Navigator.pushNamed(context, route as String);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: item['color'] as Color, size: 32),
                      const SizedBox(height: 10),
                      Text(item['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(
                          minWidth: 20, minHeight: 20),
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}