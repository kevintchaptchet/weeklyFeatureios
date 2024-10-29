import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id; // The Firestore document ID
  final String criteria;
  final String imageURL;
  final DateTime startDate;
  final DateTime endDate;
  final String tag;
  final DateTime? createdAt;
  final int images; // New field to track the number of images uploaded
  final List<ParticipantRanking> ranking;

  Challenge({
    required this.id,
    required this.criteria,
    required this.imageURL,
    required this.startDate,
    required this.endDate,
    required this.tag,
    this.createdAt,
    required this.images, // Updated field
    required this.ranking,
  });

  // Factory constructor to create a Challenge from a map
  factory Challenge.fromMap(Map<String, dynamic> map, String id) {
    return Challenge(
      id: id, // Use the provided document ID
      criteria: map['criteria'] ?? '',
      imageURL: map['imageURL'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      tag: map['tag'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      images: map['images'] ?? 0, // Updated field
      ranking: (map['ranking'] as List<dynamic>?)
          ?.map((item) => ParticipantRanking.fromMap(item))
          .toList() ??
          [],
    );
  }

  // Method to convert a Challenge instance to a map
  Map<String, dynamic> toMap() {
    return {
      'criteria': criteria,
      'imageURL': imageURL,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'tag': tag,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'images': images, // Updated field
      'ranking': ranking.map((item) => item.toMap()).toList(),
    };
  }
}

class ParticipantRanking {
  final String participantId;
  final String imageURL;
  final int rating;

  ParticipantRanking({
    required this.participantId,
    required this.imageURL,
    required this.rating,
  });

  // Factory constructor to create a ParticipantRanking from a map
  factory ParticipantRanking.fromMap(Map<String, dynamic> map) {
    return ParticipantRanking(
      participantId: map['participantId'] ?? '',
      imageURL: map['imageURL'] ?? '',
      rating: map['rating'] ?? 0,
    );
  }

  // Method to convert a ParticipantRanking instance to a map
  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'imageURL': imageURL,
      'rating': rating,
    };
  }
}
