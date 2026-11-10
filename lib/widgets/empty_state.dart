import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final bool onLightBackground;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.onLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = onLightBackground
        ? AppColors.iconMuted
        : Colors.white.withValues(alpha: 0.6);
    final titleColor = onLightBackground
        ? AppColors.cardTitle
        : Colors.white;
    final subColor = onLightBackground
        ? AppColors.cardSubtitle
        : AppColors.textOnPurpleMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: onLightBackground
                    ? AppColors.surfaceVioletTint
                    : Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: subColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
