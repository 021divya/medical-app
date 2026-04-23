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
            // 🔥 Clicking this header now goes to the new screen
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
                        context, '/edit-profile'), // 🔥 FIXED: No more dialog
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





/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Matching your app's theme colors
  static const Color primary = Color(0xFF9C89E8);
  static const Color backgroundColor = Color(0xFFF4F6FF);

  // State for user data
  String name = 'Guest User';

  // State for toggles
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
              tooltip: 'Go Back',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open Menu',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            }),
          ],
        ),
      ),
      drawer: AppDrawer(
        userName: name,
        currentRoute: '/settings',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 🔥 NEW: Profile Completion Header
            _buildProfileCompletionHeader(),
            const SizedBox(height: 10),
            _buildAccountCard(context),
            const SizedBox(height: 10),
            _buildSectionHeader('Settings'),
            _buildListTile('Notification settings', hasArrow: true),
            _buildListTile(
              'We use Full Screen Alerts permission for audio and video calls',
              isMultiline: true,
            ),
            _buildSectionHeader('Reminder Settings'),
            _buildSwitchTile(
              'Reminder volume',
              reminderVolume,
              (val) {
                setState(() => reminderVolume = val);
                _saveSetting('reminder_volume', val);
              },
            ),
            _buildSwitchTile(
              'Vibrate',
              vibrate,
              (val) {
                setState(() => vibrate = val);
                _saveSetting('vibrate', val);
              },
            ),
            _buildListTileWithSubtitle('Snooze duration', '5 minutes',
                hasArrow: true),
            _buildListTileWithSubtitle(
                'Popup notification', 'Always show popup',
                hasArrow: true),
            _buildSectionHeader('General'),
            _buildListTile('About App', hasArrow: false),
            _buildListTile('Privacy Policy', hasArrow: false),
            _buildListTile('Help and support', hasArrow: false),
            _buildListTile('Share with friends and family', hasArrow: false),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔥 NEW: Profile Header based on your Practo screenshots
  Widget _buildProfileCompletionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primary,
            child: const Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "9% completed",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.09,
                    backgroundColor: primary.withOpacity(0.1),
                    color: primary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {
              // Navigate to the detailed profile screen
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage your account information',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAccountInfoRow('Full Name', name),
                  const Divider(height: 30),
                  _buildAccountInfoRow('Email', 'user@example.com'),
                  const Divider(height: 30),
                  _buildAccountInfoRow('Phone', '+91 0000000000'),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to the detailed profile screen
                        Navigator.pushNamed(context, '/edit-profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey.withOpacity(0.1),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(String title,
      {bool hasArrow = false, bool isMultiline = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isMultiline ? 14 : 16,
          color: isMultiline ? Colors.black87 : Colors.black,
          fontWeight: isMultiline ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      trailing:
          hasArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: () {},
    );
  }

  Widget _buildListTileWithSubtitle(String title, String subtitle,
      {bool hasArrow = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing:
          hasArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      value: value,
      activeColor: Colors.white,
      activeTrackColor: primary,
      onChanged: onChanged,
    );
  }
}
*/





/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Matching your app's theme colors
  static const Color primary = Color(0xFF9C89E8);
  static const Color backgroundColor = Color(0xFFF4F6FF);

  // State for user data
  String name = 'Guest User';

  // State for toggles
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
        // 🔥 Expanded width to hold BOTH icons comfortably
        leadingWidth: 100,
        leading: Row(
          children: [
            const SizedBox(width: 8), // Small padding from the edge
            // 1. The Back Arrow
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Go Back',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            // 2. The Hamburger Menu
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open Menu',
                onPressed: () {
                  // We use Builder context so it finds the Scaffold's drawer
                  Scaffold.of(context).openDrawer();
                },
              );
            }),
          ],
        ),
      ),
      drawer: AppDrawer(
        userName: name,
        currentRoute: '/settings',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildAccountCard(context),
            const SizedBox(height: 10),
            _buildSectionHeader('Settings'),
            _buildListTile('Notification settings', hasArrow: true),
            _buildListTile(
              'We use Full Screen Alerts permission for audio and video calls',
              isMultiline: true,
            ),
            _buildSectionHeader('Reminder Settings'),
            _buildSwitchTile(
              'Reminder volume',
              reminderVolume,
              (val) {
                setState(() => reminderVolume = val);
                _saveSetting('reminder_volume', val);
              },
            ),
            _buildSwitchTile(
              'Vibrate',
              vibrate,
              (val) {
                setState(() => vibrate = val);
                _saveSetting('vibrate', val);
              },
            ),
            _buildListTileWithSubtitle('Snooze duration', '5 minutes',
                hasArrow: true),
            _buildListTileWithSubtitle(
                'Popup notification', 'Always show popup',
                hasArrow: true),
            _buildSectionHeader('General'),
            _buildListTile('About App', hasArrow: false),
            _buildListTile('Privacy Policy', hasArrow: false),
            _buildListTile('Help and support', hasArrow: false),
            _buildListTile('Share with friends and family', hasArrow: false),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🔥 Lavender Account Card Widget
  Widget _buildAccountCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Lavender Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Manage your account information',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom White Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAccountInfoRow('Full Name', name),
                  const Divider(height: 30),
                  _buildAccountInfoRow('Email', 'user@example.com'),
                  const Divider(height: 30),
                  _buildAccountInfoRow('Phone', '+91 0000000000'),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        _showEditProfileDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Profile'),
          content: const Text(
              'This will open a form to update your details once the database is connected!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it',
                  style:
                      TextStyle(color: primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey.withOpacity(0.1),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(String title,
      {bool hasArrow = false, bool isMultiline = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isMultiline ? 14 : 16,
          color: isMultiline ? Colors.black87 : Colors.black,
          fontWeight: isMultiline ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      trailing:
          hasArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: () {},
    );
  }

  Widget _buildListTileWithSubtitle(String title, String subtitle,
      {bool hasArrow = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing:
          hasArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      value: value,
      activeColor: Colors.white,
      activeTrackColor: primary,
      onChanged: onChanged,
    );
  }
}


*/