class VibeStory {
  final String id;
  final String authorId;
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  VibeStory({
    required this.id,
    required this.authorId,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  factory VibeStory.fromJson(Map<String, dynamic> json) {
    return VibeStory(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      mediaUrl: json['mediaUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'mediaUrl': mediaUrl,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}
