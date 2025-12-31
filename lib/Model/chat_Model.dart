enum MessageStatus { sent, delivered, read }

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime? timestamp;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.timestamp,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
  });

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as dynamic).toDate() 
          : null,
      isRead: data['isRead'] as bool? ?? false,
      deliveredAt: data['deliveredAt'] != null 
          ? (data['deliveredAt'] as dynamic).toDate() 
          : null,
      readAt: data['readAt'] != null 
          ? (data['readAt'] as dynamic).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'deliveredAt': deliveredAt,
      'readAt': readAt,
    };
  }

  MessageStatus getStatus(String currentUserId) {
    if (senderId != currentUserId) return MessageStatus.read;
    if (readAt != null) return MessageStatus.read;
    if (deliveredAt != null) return MessageStatus.delivered;
    return MessageStatus.sent;
  }
}

class ChatConversation {
  final String conversationId;
  final String userId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserProfileImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.conversationId,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserProfileImage,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String,
      otherUserProfileImage: json['otherUserProfileImage'] as String,
      lastMessage: json['lastMessage'] as String,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userId': userId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserProfileImage': otherUserProfileImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}
