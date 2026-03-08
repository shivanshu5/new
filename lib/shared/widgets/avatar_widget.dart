import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final bool hasStory;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.imageUrl,
    this.radius = 30.0,
    this.hasStory = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: hasStory ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
        decoration: hasStory
            ? const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              )
            : null,
        child: Container(
          padding: hasStory ? const EdgeInsets.all(2) : EdgeInsets.zero,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.surfaceAlt,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? Icon(Icons.person, color: Colors.white54, size: radius)
                : null,
          ),
        ),
      ),
    );
  }
}
