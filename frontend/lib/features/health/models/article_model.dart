class Article {
  final String id;
  final String title;
  final String author;
  final String category;
  final String imageUrl;

  int likes;
  bool isLiked;

  Article({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.imageUrl,
    this.likes = 0,
    this.isLiked = false,
  });
}
