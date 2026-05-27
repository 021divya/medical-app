import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primary = Color(0xFF9C89E8);
  static const Color backgroundColor = Color(0xFFF4F6FF);

  String name = 'Guest User';
  bool reminderVolume = true;
  bool vibrate = true;

  @override
  void initState() {
    super.initState();
    _loadPatientName();
    _loadSettings();
  }

  Future<void> _loadPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      name = prefs.getString('patient_name') ?? 'Guest User';
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      reminderVolume = prefs.getBool('reminder_volume') ?? true;
      vibrate = prefs.getBool('vibrate') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings'),
        leadingWidth: 100,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            }),
          ],
        ),
      ),
      drawer: AppDrawer(userName: name, currentRoute: '/settings'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            _buildProfileCompletionHeader(),
            _buildAccountCard(),
            _buildSectionHeader('Settings'),
            _buildListTile('Notification settings', hasArrow: true),
            _buildSectionHeader('Reminder Settings'),
            _buildSwitchTile('Reminder volume', reminderVolume, (val) {
              setState(() => reminderVolume = val);
              _saveSetting('reminder_volume', val);
            }),
            _buildSwitchTile('Vibrate', vibrate, (val) {
              setState(() => vibrate = val);
              _saveSetting('vibrate', val);
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionHeader() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/edit-profile'),
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
                radius: 30,
                backgroundColor: primary,
                child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("9% completed",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: 0.09,
                      backgroundColor: primary.withOpacity(0.1),
                      color: primary),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.8),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              child: const Row(children: [
                Icon(Icons.account_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Account",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAccountRow("Name", name),
                  const Divider(),
                  _buildAccountRow("Email", "Add email"),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                        context, '/edit-profile'), 
                    child: const Text("Edit Profile"),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(String label, String val) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(val)
      ]);
  Widget _buildSectionHeader(String t) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.black.withOpacity(0.05),
      child: Text(t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
  Widget _buildListTile(String t, {bool hasArrow = false}) => ListTile(
      title: Text(t),
      trailing: hasArrow ? const Icon(Icons.chevron_right) : null);
  Widget _buildSwitchTile(String t, bool v, Function(bool) onChanged) =>
      SwitchListTile(
          title: Text(t), value: v, activeColor: primary, onChanged: onChanged);
}
