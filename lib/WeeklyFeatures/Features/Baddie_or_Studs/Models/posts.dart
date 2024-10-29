class PostModel {
  final String postId;
  final String imageUrl;
  final String userId;
  final String criteria;
  final double rating;

  PostModel({
    required this.postId,
    required this.imageUrl,
    required this.userId,
    required this.criteria,
    this.rating = 0.0,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      userId: map['userId'] ?? '',
      criteria: map['criteria'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'imageUrl': imageUrl,
      'userId': userId,
      'criteria': criteria,
      'rating': rating,
    };
  }
}
