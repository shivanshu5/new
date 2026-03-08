class UserModel {
  final String id;
  final String displayName;
  final String bio;
  final List<String> interests;
  final String intent;
  final String profilePhotoUrl;
  final String photoPrivacy;
  final String vibeStoryVisibilityDefault;
  final bool stealthMode;
  final DateTime lastActive;
  final int xpPoints;
  final int streakCount;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.displayName,
    this.bio = '',
    this.interests = const [],
    this.intent = 'friends',
    this.profilePhotoUrl = '',
    this.photoPrivacy = 'public',
    this.vibeStoryVisibilityDefault = 'friends',
    this.stealthMode = false,
    required this.lastActive,
    this.xpPoints = 0,
    this.streakCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      bio: json['bio'] as String? ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      intent: json['intent'] as String? ?? 'friends',
      profilePhotoUrl: json['profilePhotoUrl'] as String? ?? '',
      photoPrivacy: json['photoPrivacy'] as String? ?? 'public',
      vibeStoryVisibilityDefault: json['vibeStoryVisibilityDefault'] as String? ?? 'friends',
      stealthMode: json['stealthMode'] as bool? ?? false,
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive'] as String) : DateTime.now(),
      xpPoints: json['xpPoints'] as int? ?? 0,
      streakCount: json['streakCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'bio': bio,
      'interests': interests,
      'intent': intent,
      'profilePhotoUrl': profilePhotoUrl,
      'photoPrivacy': photoPrivacy,
      'vibeStoryVisibilityDefault': vibeStoryVisibilityDefault,
      'stealthMode': stealthMode,
      'lastActive': lastActive.toIso8601String(),
      'xpPoints': xpPoints,
      'streakCount': streakCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
