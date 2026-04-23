import 'package:flutter/material.dart';
import 'medical_tab.dart';
import 'lifestyle_tab.dart';
import 'personal_tab.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Personal"),
              Tab(text: "Medical"),
              Tab(text: "Lifestyle"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PersonalTab(),
            MedicalTab(),
            LifestyleTab(),
          ],
        ),
      ),
    );
  }
}