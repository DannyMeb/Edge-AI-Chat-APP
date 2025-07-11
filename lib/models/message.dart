class Message {
  String content;
  final String role;
  final String avatar;
  final DateTime timestamp;

  // Constructor with default timestamp
  Message({
    required this.content,
    required this.role,
    required this.avatar,
  }) : timestamp = DateTime.now(); // Automatically assign current time

  // Constructor for deserializing from JSON
  Message.withTimestamp({
    required this.content,
    required this.role,
    required this.avatar,
    required this.timestamp,
  });

  // Serialize the object to JSON
  Map<String, dynamic> toJson() => {
        'content': content,
        'role': role,
        'avatar': avatar,
        'timestamp': timestamp.toIso8601String(),
      };

  // Deserialize the object from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message.withTimestamp(
      content: json['content'],
      role: json['role'],
      avatar: json['avatar'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
} 