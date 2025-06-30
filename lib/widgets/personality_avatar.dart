import 'package:flutter/material.dart';
import '../models/bot_personality.dart';

class PersonalityAvatar extends StatelessWidget {
  final BotPersonality personality;
  final double size;
  final Color? backgroundColor;
  final bool showBorder;

  const PersonalityAvatar({
    super.key,
    required this.personality,
    this.size = 32,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[400],
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: ClipOval(
        child: Image.asset(
          personality.imagePath,
          fit: BoxFit.cover,
          width: size,
          height: size,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to emoji if image fails to load
            return Center(
              child: Text(
                personality.emoji,
                style: TextStyle(fontSize: size * 0.5),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
} 