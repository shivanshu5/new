class StoryModel {
  final String id;
  final String authorId;
  final String mediaUrl;
  final String type; // 'image', 'video', 'text'
  final String visibility; // 'nearby', 'friends'
  final String? textContent; // For text stories
  final List<String> reactions; // e.g. ['🔥', '❤️']
  final DateTime createdAt;
  final DateTime expiresAt;

  StoryModel({
    required this.id,
    required this.authorId,
    required this.mediaUrl,
    required this.type,
    required this.visibility,
    this.textContent,
    this.reactions = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      mediaUrl: json['mediaUrl'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
      visibility: json['visibility'] as String? ?? 'nearby',
      textContent: json['textContent'] as String?,
      reactions: List<String>.from(json['reactions'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'mediaUrl': mediaUrl,
    'type': type,
    'visibility': visibility,
    'textContent': textContent,
    'reactions': reactions,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}
