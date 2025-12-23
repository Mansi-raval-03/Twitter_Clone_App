import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyModel {
  final String id;
  final String uid;
  final String username;
  final String handle;
  final String profileImage;
  final String content;
  final DateTime createdAt;

  ReplyModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.content,
    required this.createdAt,
  });

  factory ReplyModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReplyModel(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      username: data['username'] ?? 'User',
      handle: data['handle'] ?? '@user',
      profileImage: data['profileImage'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
