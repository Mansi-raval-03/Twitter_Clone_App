import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String username;
  final String bio;
  final String location;
  final String email;
  final String profileImage;
  final String coverImage;
  final int posts;
  final int followers;
  final int following;
  final int likes;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    required this.email,
    required this.profileImage,
    required this.coverImage,
    required this.posts,
    required this.followers,
    required this.following,
    required this.likes,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    int _toInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'] ?? '',
      location: data['location'] ?? '',
      email: data['email'] ?? '',
      profileImage: data['profileImage'] ?? '',
      coverImage: data['coverImage'] ?? '',
      posts: _toInt(data['posts'], 0),
      followers: _toInt(data['followers'], 0),
      following: _toInt(data['following'], 0),
      likes: _toInt(data['likes'], 0),
    );
  }
}
