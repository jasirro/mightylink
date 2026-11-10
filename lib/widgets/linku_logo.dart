import 'package:flutter/material.dart';

class LinkuLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool onPurpleBackground;

  const LinkuLogo({
    super.key,
    this.size = 64,
    this.showText = true,
    this.onPurpleBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    // If on purple background, use the white-outlined logo asset
    final assetPath = onPurpleBackground
        ? 'assets/logo_outlined.png'
        : 'assets/logo.png';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: size * 1.6,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to logo.png if outlined is loading
            return Image.asset(
              'assets/logo.png',
              width: size * 1.6,
              height: size,
              fit: BoxFit.contain,
            );
          },
        ),
        if (showText) ...[
          const SizedBox(height: 10),
          Text(
            'mightylink',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: onPurpleBackground ? Colors.white : const Color(0xFF18181B),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
