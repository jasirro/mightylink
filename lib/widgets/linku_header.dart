import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LinkuHeader extends StatelessWidget {
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSearchPressed;
  final bool isSearchVisible;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const LinkuHeader({
    super.key,
    this.onSettingsPressed,
    this.onSearchPressed,
    this.isSearchVisible = false,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Logo + "Linku"
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.logoBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.brandDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.brandDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Linku',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Second row: "Workspaces" title & subtitle + Settings & Search buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Workspaces',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your ideas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              // Settings Button
              IconButton(
                onPressed: onSettingsPressed,
                icon: const Icon(
                  Icons.settings,
                  color: AppColors.primaryNavy,
                  size: 26,
                ),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 4),
              // Search Button
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onSearchPressed,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.searchButtonBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryNavy,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isSearchVisible) ...[
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search workspaces...',
                hintStyle: const TextStyle(color: AppColors.subtitle),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryNavy),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ],
        ],
      ),
    );
  }
}
