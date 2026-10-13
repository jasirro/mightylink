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
      width: 62,
      height: 62,
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
              Icons.add,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
