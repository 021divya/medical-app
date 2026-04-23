import '../models/article_model.dart';

class ArticleService {
  static Future<List<Article>> getArticles() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      Article(
        id: "1",
        title: "How to Boost Your Immunity Naturally",
        author: "Dr. Ananya Sharma",
        category: "Immunity",
        imageUrl:
            "https://images.unsplash.com/photo-1584515933487-779824d29309",
        likes: 120,
      ),
      Article(
        id: "2",
        title: "Understanding Diabetes: Causes & Prevention",
        author: "Dr. Raj Mehta",
        category: "Diabetes",
        imageUrl:
            "https://images.unsplash.com/photo-1579684385127-1ef15d508118",
        likes: 98,
      ),
    ];
  }
}
