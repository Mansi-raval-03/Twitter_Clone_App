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
  final List<String> retweets;
  final List<String> comments;
  final DateTime createdAt;
  bool isLiked;
  final String retweetedBy; // transient display helper (username)
  final bool isRetweet;
  // Embedded original tweet fields (when this doc is a retweet)
  final String originalTweetId;
  final String originalUsername;
  final String originalHandle;
  final String originalProfileImage;
  final String originalContent;
  final String originalImageUrl;
  final DateTime? originalCreatedAt;

  TweetModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.handle,
    required this.profileImage,
    required this.content,
    required this.imageUrl,
    required this.likes,
    this.retweets = const [],
    required this.comments,
    required this.createdAt,
    this.isLiked = false,
    this.retweetedBy = '',
    this.isRetweet = false,
    this.originalTweetId = '',
    this.originalUsername = '',
    this.originalHandle = '',
    this.originalProfileImage = '',
    this.originalContent = '',
    this.originalImageUrl = '',
    this.originalCreatedAt,
  });

  factory TweetModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
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
      profileImage: data['profileImage'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      retweets: List<String>.from(data['retweets'] ?? []),
      comments: commentsList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiked: false,
      retweetedBy: '',
      isRetweet: data['isRetweet'] == true,
      originalTweetId: (data['originalTweetId'] ?? data['original']?['originalTweetId'])?.toString() ?? '',
      originalUsername: (data['original']?['originalUsername'] ?? '')?.toString() ?? '',
      originalHandle: (data['original']?['originalHandle'] ?? '')?.toString() ?? '',
      originalProfileImage: (data['original']?['originalProfileImage'] ?? '')?.toString() ?? '',
      originalContent: (data['original']?['originalContent'] ?? '')?.toString() ?? '',
      originalImageUrl: (data['original']?['originalImageUrl'] ?? '')?.toString() ?? '',
      originalCreatedAt: (data['original']?['originalCreatedAt'] as Timestamp?)?.toDate(),
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
