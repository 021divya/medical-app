import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';

import 'exercise_screen.dart';
import 'diet_screen.dart';
import 'articles_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String name = 'Guest User';

  @override
  void initState() {
    super.initState();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      name = prefs.getString('patient_name') ?? 'Guest User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),

      // ✅ FIXED APPBAR (NO OVERFLOW)
      appBar: AppBar(
        title: const Text("Health Module"),
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),

        actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }),
        ],
      ),

      drawer: AppDrawer(
        userName: name,
        currentRoute: '/health',
      ),

      // ✅ MODERN UI
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Explore Health",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 EXERCISE CARD
            buildHealthCard(
              context: context,
              title: "Exercise",
              subtitle: "Workout & yoga videos",
              icon: Icons.fitness_center,
              colors: [Colors.orange, Colors.deepOrange],
              screen: const ExerciseScreen(),
            ),

            const SizedBox(height: 20),

            // 🔥 DIET CARD
            buildHealthCard(
              context: context,
              title: "Diet",
              subtitle: "Medical diet charts & plans",
              icon: Icons.restaurant,
              colors: [Colors.green, Colors.teal],
              screen: const DietScreen(),
            ),

            const SizedBox(height: 20),

            // 🔥 ARTICLES CARD
            buildHealthCard(
              context: context,
              title: "Articles",
              subtitle: "Research & health insights",
              icon: Icons.menu_book,
              colors: [Colors.blue, Colors.indigo],
              screen: const ArticlesScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CARD WIDGET
  Widget buildHealthCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}



/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_medical_app/features/common/app_drawer.dart';

// 🔥 NEW SCREENS (we will create next)
import 'exercise_screen.dart';
import 'diet_screen.dart';
import 'articles_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String name = 'Guest User';

  @override
  void initState() {
    super.initState();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      name = prefs.getString('patient_name') ?? 'Guest User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),

      appBar: AppBar(
  title: const Text("Health Module"),
  backgroundColor: const Color(0xFF9C89E8),
  foregroundColor: Colors.white,
  elevation: 0,

  // 🔥 FIXED
  leadingWidth: 120, // increase space

  leading: Row(
    children: [
      const SizedBox(width: 6),

      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
      ),

      Builder(builder: (context) {
        return IconButton(
          icon: const Icon(Icons.menu),
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
        currentRoute: '/health',
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildButton(
              context,
              "Exercise",
              Colors.orange,
              const ExerciseScreen(),
            ),
            const SizedBox(height: 20),

            buildButton(
              context,
              "Diet",
              Colors.green,
              const DietScreen(),
            ),
            const SizedBox(height: 20),

            buildButton(
              context,
              "Articles",
              Colors.blue,
              const ArticlesScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(
      BuildContext context, String title, Color color, Widget screen) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
*/