import 'package:cloud_firestore/cloud_firestore.dart';

class PostWithUser {
  final String postId;
  final String userId;
  final String title;
  final String description;
  final String collectingPlace;
  final String location;
  final String country;

  final String imgBBUrl; // Changed from imageUrl

  final String userName;
  final String userphotoUrl;
  final Timestamp timestamp;

  PostWithUser({
    required this.postId,
    required this.userId,
    required this.title,
    required this.description,
    required this.collectingPlace,
    required this.location,
    required this.country,
    required this.imgBBUrl, // Changed from imageUrl
    required this.userName,
    required this.userphotoUrl,
    required this.timestamp,
  });

  factory PostWithUser.fromMap(Map<String, dynamic> map) {
    return PostWithUser(
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      collectingPlace: map['collectingPlace'] ?? '',
      location: map['location'] ?? '',
      country: map['country'] ?? '',
      imgBBUrl: map['imgBBUrl'] ?? '', // Changed from imageUrl
      userName: map['userName'] ?? '',
      userphotoUrl: map['userphotoUrl'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
