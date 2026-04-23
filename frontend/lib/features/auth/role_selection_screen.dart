import 'package:flutter/material.dart';

// ✅ Role selection screen ab bypass ho gayi hai
// Seedha /auth pe redirect karti hai
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/auth');
    });

    return const Scaffold(
      backgroundColor: Color(0xFFF3EFFF),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9C89E8),
        ),
      ),
    );
  }
}

