import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/health_service.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  late Future<List<dynamic>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = HealthService.fetchHealthContent();
  }

  Future<void> openLink(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  IconData getIcon(String title) {
    title = title.toLowerCase();
    if (title.contains("weight loss")) return Icons.monitor_weight;
    if (title.contains("weight gain")) return Icons.fitness_center;
    if (title.contains("diabetic")) return Icons.bloodtype;
    if (title.contains("kid")) return Icons.child_care;
    if (title.contains("pcos") || title.contains("pcod")) return Icons.female;
    if (title.contains("kidney")) return Icons.water_drop;
    if (title.contains("cholesterol")) return Icons.favorite;
    if (title.contains("muscle")) return Icons.sports_gymnastics;
    if (title.contains("balanced")) return Icons.balance;
    return Icons.restaurant;
  }

  Color getIconColor(int index) {
    final colors = [
      const Color(0xFF9C89E8),
      Colors.teal,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text("Diet Plans"),
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF9C89E8)),
                  SizedBox(height: 16),
                  Text("Loading diet plans...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text("Could not load diet plans",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      futureData = HealthService.fetchHealthContent();
                    }),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final diet = (snapshot.data ?? [])
              .where((item) => item['category'] == 'diet')
              .toList();

          if (diet.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text("No diet plans found",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      futureData = HealthService.fetchHealthContent();
                    }),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: diet.length,
            itemBuilder: (context, index) {
              final item = diet[index];
              final color = getIconColor(index);

              return GestureDetector(
                onTap: () => openLink(item['url'] ?? ''),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(getIcon(item['title'] ?? ''),
                            color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_new,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}