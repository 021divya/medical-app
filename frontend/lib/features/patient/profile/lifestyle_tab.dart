import 'package:flutter/material.dart';
import 'profile_question_flow.dart';

class LifestyleTab extends StatefulWidget {
  const LifestyleTab({super.key});

  @override
  State<LifestyleTab> createState() => _LifestyleTabState();
}

class _LifestyleTabState extends State<LifestyleTab> {
  String? smoking;
  String? alcohol;
  String? activity;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [

        ListTile(
          title: const Text("Smoking"),
          trailing: Text(smoking ?? "Add details"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "Do you smoke?",
                  fieldKey: "smoking",
                  initialValue: smoking,
                ),
              ),
            );

            if (result != null) {
              setState(() => smoking = result);
            }
          },
        ),

        ListTile(
          title: const Text("Alcohol"),
          trailing: Text(alcohol ?? "Add details"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "Do you consume alcohol?",
                  fieldKey: "alcohol",
                  initialValue: alcohol,
                ),
              ),
            );

            if (result != null) {
              setState(() => alcohol = result);
            }
          },
        ),

        ListTile(
          title: const Text("Activity Level"),
          trailing: Text(activity ?? "Add details"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "What is your activity level?",
                  fieldKey: "activity_level",
                  initialValue: activity,
                ),
              ),
            );

            if (result != null) {
              setState(() => activity = result);
            }
          },
        ),
      ],
    );
  }
}