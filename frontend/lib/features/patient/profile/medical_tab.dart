import 'package:flutter/material.dart';
import 'profile_question_flow.dart';

class MedicalTab extends StatefulWidget {
  const MedicalTab({super.key});

  @override
  State<MedicalTab> createState() => _MedicalTabState();
}

class _MedicalTabState extends State<MedicalTab> {
  String? allergies;
  String? medications;
  String? diseases;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [

        ListTile(
          title: const Text("Allergies"),
          trailing: Text(allergies ?? "Add allergies"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "Do you have any allergies?",
                  fieldKey: "allergies",
                  initialValue: allergies,
                ),
              ),
            );

            if (result != null) {
              setState(() => allergies = result);
            }
          },
        ),

        ListTile(
          title: const Text("Medications"),
          trailing: Text(medications ?? "Add medications"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "Are you taking any medications?",
                  fieldKey: "medications",
                  initialValue: medications,
                ),
              ),
            );

            if (result != null) {
              setState(() => medications = result);
            }
          },
        ),

        ListTile(
          title: const Text("Chronic Diseases"),
          trailing: Text(diseases ?? "Add details"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "Do you have any chronic diseases?",
                  fieldKey: "chronic_diseases",
                  initialValue: diseases,
                ),
              ),
            );

            if (result != null) {
              setState(() => diseases = result);
            }
          },
        ),
      ],
    );
  }
}