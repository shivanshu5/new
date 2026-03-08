class ChatMessage {
  final String id;
  final String fromUser;
  final String text;
  final DateTime createdAt;
  final List<String> seenBy;

  ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    required this.createdAt,
    this.seenBy = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      fromUser: json['fromUser'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUser': fromUser,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'seenBy': seenBy,
  };
}
