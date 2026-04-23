import 'package:flutter/material.dart';
import 'profile_question_flow.dart';

class PersonalTab extends StatefulWidget {
  const PersonalTab({super.key});

  @override
  State<PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {
  String? email;
  String? phone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [

        ListTile(
          title: const Text("Email"),
          trailing: Text(email ?? "Add email"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "What is your email?",
                  fieldKey: "email",
                  initialValue: email,
                ),
              ),
            );

            if (result != null) {
              setState(() => email = result);
            }
          },
        ),

        ListTile(
          title: const Text("Phone"),
          trailing: Text(phone ?? "Add phone"),

          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileQuestionFlow(
                  title: "What is your phone number?",
                  fieldKey: "phone",
                  initialValue: phone,
                ),
              ),
            );

            if (result != null) {
              setState(() => phone = result);
            }
          },
        ),
      ],
    );
  }
}