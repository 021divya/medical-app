import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/services/api_service.dart';
import '../patient/profile/profile_question_flow.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {

  static const Color lightLavender = Color(0xFFF3EFFF);
  static const Color darkLavender = Color(0xFF6A5ACD);

  String name = 'Guest User';
  bool isSaving = false;
  bool isLoading = true; // ✅ Loading state

  // PERSONAL
  String? email, phone, gender, dob, bloodGroup, maritalStatus,
      height, weight, emergencyContact;

  // MEDICAL
  String? allergies, medications, pastMedications, diseases, injuries, surgeries;

  // LIFESTYLE
  String? smoking, alcohol, activity, foodPreference, occupation;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Load from backend first, fallback to SharedPreferences
  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    // Load from backend
    if (userId != 0) {
      final data = await ApiService.getProfile(userId);
      if (data != null && mounted) {
        setState(() {
          name = data['full_name'] ?? data['name'] ?? prefs.getString('patient_name') ?? 'Guest User';
          email = data['email'];
          phone = data['phone'];
          gender = data['gender'];
          dob = data['dob'];
          bloodGroup = data['blood_group'];
          maritalStatus = data['marital_status'];
          height = data['height'];
          weight = data['weight'];
          emergencyContact = data['emergency_contact'];
          allergies = data['allergies'];
          medications = data['medications'];
          pastMedications = data['past_medications'];
          diseases = data['chronic_diseases'];
          injuries = data['injuries'];
          surgeries = data['surgeries'];
          smoking = data['smoking'];
          alcohol = data['alcohol'];
          activity = data['activity_level'];
          foodPreference = data['food_preference'];
          occupation = data['occupation'];
        });
      }
    } else {
      // Fallback to SharedPreferences
      setState(() {
        name = prefs.getString('patient_name') ?? 'Guest User';
        email = prefs.getString('profile_email');
        phone = prefs.getString('profile_phone');
        gender = prefs.getString('profile_gender');
        dob = prefs.getString('profile_dob');
        bloodGroup = prefs.getString('profile_blood_group');
        maritalStatus = prefs.getString('profile_marital_status');
        height = prefs.getString('profile_height');
        weight = prefs.getString('profile_weight');
        emergencyContact = prefs.getString('profile_emergency_contact');
        allergies = prefs.getString('profile_allergies');
        medications = prefs.getString('profile_medications');
        pastMedications = prefs.getString('profile_past_medications');
        diseases = prefs.getString('profile_chronic_diseases');
        injuries = prefs.getString('profile_injuries');
        surgeries = prefs.getString('profile_surgeries');
        smoking = prefs.getString('profile_smoking');
        alcohol = prefs.getString('profile_alcohol');
        activity = prefs.getString('profile_activity_level');
        foodPreference = prefs.getString('profile_food_preference');
        occupation = prefs.getString('profile_occupation');
      });
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ✅ Save to backend + SharedPreferences cache
  Future<void> _saveProfileToBackend() async {
    setState(() => isSaving = true);

    final data = {
      if (name.isNotEmpty) "name": name,
      if (email != null) "email": email,
      if (phone != null) "phone": phone,
      if (gender != null) "gender": gender,
      if (dob != null) "dob": dob,
      if (bloodGroup != null) "blood_group": bloodGroup,
      if (maritalStatus != null) "marital_status": maritalStatus,
      if (height != null) "height": height,
      if (weight != null) "weight": weight,
      if (emergencyContact != null) "emergency_contact": emergencyContact,
      if (allergies != null) "allergies": allergies,
      if (medications != null) "medications": medications,
      if (pastMedications != null) "past_medications": pastMedications,
      if (diseases != null) "chronic_diseases": diseases,
      if (injuries != null) "injuries": injuries,
      if (surgeries != null) "surgeries": surgeries,
      if (smoking != null) "smoking": smoking,
      if (alcohol != null) "alcohol": alcohol,
      if (activity != null) "activity_level": activity,
      if (foodPreference != null) "food_preference": foodPreference,
      if (occupation != null) "occupation": occupation,
    };

    bool success = await ApiService.updateProfile(data);

    // ✅ Also cache locally so it survives page reload
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('patient_name', name);
      if (email != null) await prefs.setString('profile_email', email!);
      if (phone != null) await prefs.setString('profile_phone', phone!);
      if (gender != null) await prefs.setString('profile_gender', gender!);
      if (dob != null) await prefs.setString('profile_dob', dob!);
      if (bloodGroup != null) await prefs.setString('profile_blood_group', bloodGroup!);
      if (maritalStatus != null) await prefs.setString('profile_marital_status', maritalStatus!);
      if (height != null) await prefs.setString('profile_height', height!);
      if (weight != null) await prefs.setString('profile_weight', weight!);
      if (emergencyContact != null) await prefs.setString('profile_emergency_contact', emergencyContact!);
      if (allergies != null) await prefs.setString('profile_allergies', allergies!);
      if (medications != null) await prefs.setString('profile_medications', medications!);
      if (pastMedications != null) await prefs.setString('profile_past_medications', pastMedications!);
      if (diseases != null) await prefs.setString('profile_chronic_diseases', diseases!);
      if (injuries != null) await prefs.setString('profile_injuries', injuries!);
      if (surgeries != null) await prefs.setString('profile_surgeries', surgeries!);
      if (smoking != null) await prefs.setString('profile_smoking', smoking!);
      if (alcohol != null) await prefs.setString('profile_alcohol', alcohol!);
      if (activity != null) await prefs.setString('profile_activity_level', activity!);
      if (foodPreference != null) await prefs.setString('profile_food_preference', foodPreference!);
      if (occupation != null) await prefs.setString('profile_occupation', occupation!);
    }

    setState(() => isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Profile saved successfully ✅" : "Failed to save ❌"),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patient_name', newName);
    setState(() => name = newName);
    await ApiService.updateProfile({"name": newName});
  }

  void _editNameDialog() {
    final controller = TextEditingController(text: name);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Name"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Name is required";
              if (value.trim().length < 2) return "Name too short";
              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) return "Only letters allowed";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _saveName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editPhoneDialog() {
    final controller = TextEditingController(text: phone?.replaceAll('+91 ', ''));
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Contact Number"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: "Phone Number", prefixText: "+91 ", border: OutlineInputBorder(), hintText: "10 digit mobile number"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Phone is required";
              if (value.trim().length != 10) return "Enter 10 digit number";
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) return "Enter a valid Indian mobile number";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() => phone = "+91 ${controller.text.trim()}");
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editEmailDialog() {
    final controller = TextEditingController(text: email);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Email Address"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), hintText: "user@example.com"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Email is required";
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(value.trim())) return "Enter a valid email";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() => email = controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _editDobDialog() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: "Select Date of Birth",
    );
    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() => dob = formatted);
    }
  }

  void _editGenderDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select Gender"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Male', 'Female', 'Other'].map((g) {
            return ListTile(
              title: Text(g),
              leading: Radio<String>(
                value: g, groupValue: gender,
                onChanged: (val) { setState(() => gender = val); Navigator.pop(context); },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editBloodGroupDialog() {
    final groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select Blood Group"),
        content: Wrap(
          spacing: 8, runSpacing: 8,
          children: groups.map((g) {
            final isSelected = bloodGroup == g;
            return GestureDetector(
              onTap: () { setState(() => bloodGroup = g); Navigator.pop(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? darkLavender : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? darkLavender : Colors.grey.shade300),
                ),
                child: Text(g, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editHeightDialog() {
    final controller = TextEditingController(text: height?.replaceAll(' cm', ''));
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Height"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: "Height", border: OutlineInputBorder(), suffixText: "cm", hintText: "e.g. 170"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Height is required";
              final h = int.tryParse(value.trim());
              if (h == null) return "Enter a valid number";
              if (h < 50 || h > 250) return "Height must be between 50 and 250 cm";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() => height = "${controller.text.trim()} cm");
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editWeightDialog() {
    final controller = TextEditingController(text: weight?.replaceAll(' kg', ''));
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Weight"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: "Weight", border: OutlineInputBorder(), suffixText: "kg", hintText: "e.g. 65"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Weight is required";
              final w = int.tryParse(value.trim());
              if (w == null) return "Enter a valid number";
              if (w < 10 || w > 300) return "Weight must be between 10 and 300 kg";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() => weight = "${controller.text.trim()} kg");
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editEmergencyDialog() {
    final controller = TextEditingController(text: emergencyContact?.replaceAll('+91 ', ''));
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Emergency Contact"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: const InputDecoration(labelText: "Phone Number", prefixText: "+91 ", border: OutlineInputBorder(), hintText: "10 digit mobile number"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Contact is required";
              if (value.trim().length != 10) return "Enter 10 digit number";
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) return "Enter a valid Indian mobile number";
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() => emergencyContact = "+91 ${controller.text.trim()}");
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> openFlow(String title, String key, Function(String) setter, String? initial) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileQuestionFlow(title: title, fieldKey: key, initialValue: initial),
      ),
    );
    if (result != null) setState(() => setter(result));
  }

  Widget buildSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(children: children),
    );
  }

  Widget buildListItem({
    required String title,
    required String trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(trailing, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightLavender,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darkLavender,
        onPressed: isSaving ? null : _saveProfileToBackend,
        icon: isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save),
        label: Text(isSaving ? "Saving..." : "Save Profile"),
      ),
      appBar: AppBar(
        backgroundColor: darkLavender,
        foregroundColor: Colors.white,
        title: Text(name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Personal"),
            Tab(text: "Medical"),
            Tab(text: "Lifestyle"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── PERSONAL ─────────────────────────────────────────
                SingleChildScrollView(
                  child: buildSection([
                    buildListItem(title: "Name", trailing: name, onTap: _editNameDialog),
                    buildListItem(title: "Contact Number", trailing: phone ?? "Add contact", onTap: _editPhoneDialog),
                    buildListItem(title: "Email Id", trailing: email ?? "Add email", onTap: _editEmailDialog),
                    buildListItem(title: "Gender", trailing: gender ?? "Add gender", onTap: _editGenderDialog),
                    buildListItem(title: "Date of Birth", trailing: dob ?? "DD-MM-YYYY", onTap: _editDobDialog),
                    buildListItem(title: "Blood Group", trailing: bloodGroup ?? "Add blood group", onTap: _editBloodGroupDialog),
                    buildListItem(
                      title: "Marital Status", trailing: maritalStatus ?? "Add marital status",
                      onTap: () => openFlow("Select marital status", "marital_status", (v) => maritalStatus = v, maritalStatus),
                    ),
                    buildListItem(title: "Height", trailing: height ?? "Add height (cm)", onTap: _editHeightDialog),
                    buildListItem(title: "Weight", trailing: weight ?? "Add weight (kg)", onTap: _editWeightDialog),
                    buildListItem(title: "Emergency Contact", trailing: emergencyContact ?? "Add emergency details", onTap: _editEmergencyDialog, showDivider: false),
                  ]),
                ),

                // ── MEDICAL ──────────────────────────────────────────
                SingleChildScrollView(
                  child: buildSection([
                    buildListItem(title: "Allergies", trailing: allergies ?? "Add allergies",
                      onTap: () => openFlow("Do you have any allergies?", "allergies", (v) => allergies = v, allergies)),
                    buildListItem(title: "Current Medications", trailing: medications ?? "Add medications",
                      onTap: () => openFlow("Current medications?", "medications", (v) => medications = v, medications)),
                    buildListItem(title: "Past Medications", trailing: pastMedications ?? "Add medications",
                      onTap: () => openFlow("Past medications?", "past_medications", (v) => pastMedications = v, pastMedications)),
                    buildListItem(title: "Chronic Diseases", trailing: diseases ?? "Add disease",
                      onTap: () => openFlow("Any chronic diseases?", "chronic_diseases", (v) => diseases = v, diseases)),
                    buildListItem(title: "Injuries", trailing: injuries ?? "Add incident",
                      onTap: () => openFlow("Any injuries?", "injuries", (v) => injuries = v, injuries)),
                    buildListItem(title: "Surgeries", trailing: surgeries ?? "Add surgeries",
                      onTap: () => openFlow("Any surgeries?", "surgeries", (v) => surgeries = v, surgeries), showDivider: false),
                  ]),
                ),

                // ── LIFESTYLE ─────────────────────────────────────────
                SingleChildScrollView(
                  child: buildSection([
                    buildListItem(title: "Smoking Habits", trailing: smoking ?? "Add details",
                      onTap: () => openFlow("Do you smoke?", "smoking", (v) => smoking = v, smoking)),
                    buildListItem(title: "Alcohol Consumption", trailing: alcohol ?? "Add details",
                      onTap: () => openFlow("Alcohol consumption?", "alcohol", (v) => alcohol = v, alcohol)),
                    buildListItem(title: "Activity Level", trailing: activity ?? "Add details",
                      onTap: () => openFlow("Activity level?", "activity_level", (v) => activity = v, activity)),
                    buildListItem(title: "Food Preference", trailing: foodPreference ?? "Add lifestyle",
                      onTap: () => openFlow("Food preference?", "food_preference", (v) => foodPreference = v, foodPreference)),
                    buildListItem(title: "Occupation", trailing: occupation ?? "Add occupation",
                      onTap: () => openFlow("Your occupation?", "occupation", (v) => occupation = v, occupation), showDivider: false),
                  ]),
                ),
              ],
            ),
    );
  }
}