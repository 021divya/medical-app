import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'video_player_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late Future<List<dynamic>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = HealthService.fetchHealthContent();
  }

  // ✅ Works for BOTH youtube.com & youtu.be links
  String getVideoId(String url) {
    try {
      if (url.contains("v=")) {
        return url.split("v=")[1].split("&")[0];
      } else if (url.contains("youtu.be/")) {
        final part = url.split("youtu.be/")[1];
        return part.split("?")[0].split("&")[0];
      }
    } catch (_) {}
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text("Exercises"),
        backgroundColor: const Color(0xFF9C89E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          // ─── Loading ───
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF9C89E8)),
                  SizedBox(height: 16),
                  Text("Loading exercises...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // ─── Error ───
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    "Could not load exercises",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
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

          // ─── Filter exercises ───
          final exercises = (snapshot.data ?? [])
              .where((item) => item['category'] == 'exercise')
              .toList();

          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    "No exercises found",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Check your server connection",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final item = exercises[index];
              final videoId = getVideoId(item['url'] ?? '');

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        videoUrl: item['url'],
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Thumbnail ───
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: videoId.isNotEmpty
                                ? Image.network(
                                    "https://img.youtube.com/vi/$videoId/hqdefault.jpg",
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholderThumbnail(),
                                  )
                                : _placeholderThumbnail(),
                          ),
                          // Play overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                color: Colors.black.withOpacity(0.15),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ─── Title ───
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['title'] ?? 'Exercise',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFF9C89E8)),
                          ],
                        ),
                      ),
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

  Widget _placeholderThumbnail() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFE8E4FF),
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            size: 56, color: Color(0xFF9C89E8)),
      ),
    );
  }
}