import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/saved_link.dart';
import '../theme/app_colors.dart';

class SavedLinkCard extends StatelessWidget {
  final SavedLink link;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const SavedLinkCard({
    super.key,
    required this.link,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  _PlatformInfo _getPlatformInfo(String url, String title) {
    final lowerUrl = url.toLowerCase();
    final lowerTitle = title.toLowerCase();

    if (lowerUrl.contains('claude.ai') || lowerUrl.contains('anthropic') || lowerTitle.contains('claude')) {
      return const _PlatformInfo(
        name: 'Claude',
        tag: 'claude',
        icon: Icons.wb_sunny_rounded,
        backgroundColor: Color(0xFFFFF7ED),
        iconColor: Color(0xFFC2410C),
        textColor: Color(0xFF9A3412),
      );
    } else if (lowerUrl.contains('chatgpt') || lowerUrl.contains('openai') || lowerTitle.contains('chatgpt')) {
      return const _PlatformInfo(
        name: 'ChatGPT',
        tag: 'chatgpt',
        icon: Icons.circle,
        backgroundColor: Color(0xFFECFDF5),
        iconColor: Color(0xFF10B981),
        textColor: Color(0xFF065F46),
      );
    } else if (lowerUrl.contains('github.com') || lowerTitle.contains('postiz') || lowerTitle.contains('github')) {
      return const _PlatformInfo(
        name: 'Postiz App',
        tag: 'github',
        icon: Icons.code_rounded,
        backgroundColor: Color(0xFF111827),
        iconColor: Colors.white,
        textColor: Colors.white,
      );
    } else if (lowerUrl.contains('flutter.dev') || lowerTitle.contains('flutter')) {
      return const _PlatformInfo(
        name: 'Flutter Dev',
        tag: 'flutter',
        icon: Icons.flutter_dash,
        backgroundColor: Color(0xFFE0F2FE),
        iconColor: Color(0xFF0284C7),
        textColor: Color(0xFF0369A1),
      );
    } else if (lowerUrl.contains('dart.dev') || lowerTitle.contains('dart')) {
      return const _PlatformInfo(
        name: 'Dart Lang',
        tag: 'dart.dev',
        icon: Icons.article_rounded,
        backgroundColor: Color(0xFFEFF6FF),
        iconColor: Color(0xFF2563EB),
        textColor: Color(0xFF1D4ED8),
      );
    } else if (lowerUrl.contains('pub.dev') || lowerTitle.contains('pub.dev') || lowerTitle.contains('package')) {
      return const _PlatformInfo(
        name: 'Pub.dev',
        tag: 'pub.dev',
        icon: Icons.inventory_2_outlined,
        backgroundColor: Color(0xFFECFDF5),
        iconColor: Color(0xFF059669),
        textColor: Color(0xFF065F46),
      );
    } else if (lowerUrl.contains('youtube') || lowerUrl.contains('youtu.be') || lowerTitle.contains('tutorial')) {
      return const _PlatformInfo(
        name: 'Tutorial',
        tag: 'video',
        icon: Icons.play_arrow_rounded,
        backgroundColor: Color(0xFFFDF2F8),
        iconColor: Color(0xFFDB2777),
        textColor: Color(0xFF9D174D),
      );
    } else if (lowerUrl.contains('stackoverflow') || lowerTitle.contains('q&a') || lowerTitle.contains('build error')) {
      return const _PlatformInfo(
        name: 'Q&A Solved',
        tag: 'stack',
        icon: Icons.layers_rounded,
        backgroundColor: Color(0xFFFFFBEB),
        iconColor: Color(0xFFD97706),
        textColor: Color(0xFF92400E),
      );
    }

    String domain = '';
    try {
      final uri = Uri.parse(url);
      domain = uri.host.replaceFirst('www.', '');
    } catch (_) {
      domain = 'web';
    }
    if (domain.isEmpty) domain = 'link';

    return _PlatformInfo(
      name: domain,
      tag: domain.split('.').first,
      icon: Icons.public_rounded,
      backgroundColor: const Color(0xFFF1F5F9),
      iconColor: const Color(0xFF475569),
      textColor: const Color(0xFF334155),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformInfo = _getPlatformInfo(link.url, link.title);
    final dateStr = DateFormat('d/M').format(link.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: const [AppColors.linkCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: date and link badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.linkBadgeBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.link_rounded,
                          size: 13,
                          color: AppColors.linkBadgeIcon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Middle: preview box with platform logo/title
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: platformInfo.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        platformInfo.icon,
                        size: 16,
                        color: platformInfo.iconColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        platformInfo.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: platformInfo.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Title and description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cardTitle,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.note.isNotEmpty ? link.note : link.url,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Footer: tag chip, sparkle action icon, delete icon
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tagBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFDBEAFE),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            platformInfo.tag,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tagText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          link.isFavorite ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                          size: 14,
                          color: AppColors.sparklePurple,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: AppColors.deleteRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformInfo {
  final String name;
  final String tag;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const _PlatformInfo({
    required this.name,
    required this.tag,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });
}
