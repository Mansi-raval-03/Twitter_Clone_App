import 'package:cloud_firestore/cloud_firestore.dart';

class TweetModel {
  final String id;
  final String uid;
  final String username;
  final String handle;
  final String profileImage;
  final String content;
  final String imageUrl;
  final List<String> likes;
  final List<String> comments;
  final DateTime createdAt;
  bool isLiked;

  TweetModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.content,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.isLiked = false,
  });

  factory TweetModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safely parse comments - handle both string IDs and Map objects
    List<String> commentsList = [];
    final commentsData = data['comments'];
    if (commentsData is List) {
      for (var item in commentsData) {
        if (item is String) {
          commentsList.add(item);
        } else if (item is Map) {
          // If it's a Map object (old data format), just count it
          commentsList.add('comment_${DateTime.now().millisecondsSinceEpoch}');
        }
      }
    }
    
    return TweetModel(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      username: data['username'] ?? 'User',
      handle: data['handle'] ?? '@user',
      profileImage: data['profileImage'] ?? 'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      comments: commentsList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiked: false,
    );
  }

  void like() {
    isLiked = true;
    // Optionally update likes list
  }

  void unlike() {
    isLiked = false;
    // Optionally update likes list
  }
}
