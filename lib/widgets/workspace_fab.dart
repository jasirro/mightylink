import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WorkspaceFab extends StatelessWidget {
  final VoidCallback onPressed;

  const WorkspaceFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.fabGreen,
        shape: BoxShape.circle,
        boxShadow: [AppColors.fabShadow],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
