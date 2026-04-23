import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/health_service.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
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

  IconData getArticleIcon(String title) {
    title = title.toLowerCase();
    if (title.contains("cardiac") || title.contains("heart")) return Icons.favorite;
    if (title.contains("cancer")) return Icons.science;
    if (title.contains("autism")) return Icons.psychology;
    if (title.contains("pregnanc") || title.contains("fetal") ||
        title.contains("childbirth") || title.contains("maternal") ||
        title.contains("postpartum") || title.contains("midwi")) {
      return Icons.pregnant_woman;
    }
    if (title.contains("diet")) return Icons.restaurant;
    if (title.contains("virus") || title.contains("infection") ||
        title.contains("bacteremia") || title.contains("lung")) {
      return Icons.coronavirus;
    }
    return Icons.article;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text("Health Articles"),
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
                  Text("Loading articles...", style: TextStyle(color: Colors.grey)),
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
                  const Text("Could not load articles",
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

          // ✅ FIXED: category is 'health' in the backend, not 'article'
          final articles = (snapshot.data ?? [])
              .where((item) => item['category'] == 'health')
              .toList();

          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text("No articles found",
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
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final item = articles[index];

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
                          color: const Color(0xFF9C89E8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          getArticleIcon(item['title'] ?? ''),
                          color: const Color(0xFF9C89E8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Research Article • Tap to read",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
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