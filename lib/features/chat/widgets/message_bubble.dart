import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isRead;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.isRead,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 60 : 16,
            right: isMe ? 16 : 60,
            top: 3,
            bottom: 3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            gradient: isMe ? AppTheme.primaryGradient : null,
            color: isMe ? null : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
            ),
            boxShadow: isMe
                ? [BoxShadow(color: AppTheme.violet.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.check,
                      size: 13,
                      color: isRead ? AppTheme.mint : Colors.white54,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
