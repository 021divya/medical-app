import 'package:flutter/material.dart';


class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Seedha auth screen pe bhejo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/auth');
    });

    // Ek baar ke liye loading screen
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
