import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'linku_logo.dart';

class LinkuHeader extends StatelessWidget {
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSearchPressed;
  final bool isSearchVisible;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String title;
  final String subtitle;
  final String selectedFilter;
  final ValueChanged<String>? onFilterSelected;

  const LinkuHeader({
    super.key,
    this.onSettingsPressed,
    this.onSearchPressed,
    this.isSearchVisible = false,
    this.searchController,
    this.onSearchChanged,
    this.title = 'Workspaces',
    this.subtitle = 'Manage your links',
    this.selectedFilter = 'All',
    this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Mini Bar: Brand Logo & Right Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LinkuLogo(
                size: 36,
                showText: false,
                onPurpleBackground: true,
              ),
              Row(
                children: [
                  if (onSearchPressed != null) ...[
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onSearchPressed,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSearchVisible
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSearchVisible ? Icons.close : Icons.search_rounded,
                            color: isSearchVisible
                                ? AppColors.primaryViolet
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onSettingsPressed != null) ...[
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onSettingsPressed,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Title & Subtitle in White
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPurpleMuted,
            ),
          ),
          if (isSearchVisible) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Search workspaces, links, notes...',
                  hintStyle: TextStyle(color: AppColors.iconMuted, fontWeight: FontWeight.normal),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryViolet),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: onSearchChanged,
              ),
            ),
            if (onFilterSelected != null) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Workspaces', 'Links', 'Favorites'].map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => onFilterSelected!(filter),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentYellow
                                : Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? AppColors.yellowButtonText : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
