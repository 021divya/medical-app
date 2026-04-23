import 'package:flutter/material.dart';
import 'package:ai_medical_app/services/api_service.dart';

class ProfileQuestionFlow extends StatefulWidget {
  final String title;
  final String fieldKey;
  final String? initialValue;

  const ProfileQuestionFlow({
    super.key,
    required this.title,
    required this.fieldKey,
    this.initialValue,
  });

  @override
  State<ProfileQuestionFlow> createState() => _ProfileQuestionFlowState();
}

class _ProfileQuestionFlowState extends State<ProfileQuestionFlow> {
  late TextEditingController controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue ?? "");
  }

  @override
  void dispose() {
    controller.dispose(); // ✅ IMPORTANT (memory fix)
    super.dispose();
  }

  // ✅ SAVE FUNCTION
  Future<void> saveData() async {
    final value = controller.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter something")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = {
        widget.fieldKey: value,
      };

      //bool success = await ApiService.updateProfile(1, data); // TODO: replace userId later
bool success = await ApiService.updateProfile(data);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, value); // ✅ return value
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save ❌")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E3192),
      resizeToAvoidBottomInset: true, // ✅ fixes keyboard overflow
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: isLoading ? null : saveData,
                    child: const Text(
                      "SAVE",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🔹 QUESTION TEXT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // 🔹 INPUT SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true, // ✅ better UX
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "Enter details",
                      border: UnderlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Press SAVE to store your information.",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  if (isLoading)
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}