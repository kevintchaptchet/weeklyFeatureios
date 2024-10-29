// Updated UserModel class

class UserModel {
  final String id;
  final String username;
  final String? photoUrl;
  final String bio;
  final int ul;
  final bool hasCompletedOnboarding; // New field

  UserModel({
    required this.id,
    required this.username,
    this.photoUrl,
    this.bio = '',
    this.ul = 2,
    this.hasCompletedOnboarding = false, // Default value
  });

  // Factory method to create a UserModel from Firestore data
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      photoUrl: map['photoUrl'],
      bio: map['bio'] ?? '',
      ul: map['ul'] ?? 2,
      hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'username': username,
      'photoUrl': photoUrl,
      'bio': bio,
      'ul': ul,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      // Add other fields as necessary
    };
  }
}
