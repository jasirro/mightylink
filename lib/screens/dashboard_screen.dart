import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import '../services/db_service.dart';
import '../services/dashboard_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/workspace_fab.dart';
import 'add_link_screen.dart';
import 'home_screen.dart';
import 'cloud_sync_screen.dart';
import 'dashboard/extension_sheet.dart';
import 'dashboard/reminders_sheet.dart';
import 'dashboard/vault_sheet.dart';
import 'dashboard/sharing_sheet.dart';
import 'dashboard/team_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _openExtensionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExtensionSheet(),
    );
  }

  void _openRemindersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RemindersSheet(),
    ).then((_) => setState(() {}));
  }

  void _openVaultSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VaultSheet(),
    ).then((_) => setState(() {}));
  }

  void _openSharingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SharingSheet(),
    ).then((_) => setState(() {}));
  }

  void _openTeamSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TeamSheet(),
    ).then((_) => setState(() {}));
  }

  void _showAddLinkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLinkScreen(),
    );
  }

  void _openAllSavedLinks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = DbService.activeUser.isNotEmpty ? DbService.activeUser : 'Alex';
    final reminders = DashboardService.getReminders();
    final pendingReminders = reminders.where((r) => !r.isCompleted).length;
    final vaultItems = DashboardService.getVaultItems();
    final sharedBundles = DashboardService.getSharedBundles();
    final teamMembers = DashboardService.getTeamMembers();

    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Box<SavedLink>>(
          valueListenable: DbService.linksBox.listenable(),
          builder: (context, linksBox, _) {
            final totalSavedLinks = linksBox.values.length;

            return ValueListenableBuilder<Box<Group>>(
              valueListenable: DbService.groupsBox.listenable(),
              builder: (context, groupsBox, _) {
                final totalWorkspaces = groupsBox.values.length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Profile & Welcome Card (Figma Node 5-2928 header)
                      _buildHeaderCard(activeUser, totalSavedLinks, totalWorkspaces)
                          .animate()
                          .fade(duration: 300.ms)
                          .slideY(begin: -0.05, duration: 300.ms),

                      const SizedBox(height: 16),

                      // Quick Metrics / Action Row (4 Pill Buttons)
                      _buildQuickMetricsRow(pendingReminders, vaultItems.length, sharedBundles.length)
                          .animate()
                          .fade(duration: 300.ms, delay: 60.ms),

                      const SizedBox(height: 18),

                      // 2-Column Hero Feature Grid (Figma Node 5-2928 Core Feature Cards)
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroCard(
                              title: 'Extension',
                              subtitle: 'Browser Companion',
                              badgeText: 'Active',
                              badgeColor: AppColors.fabGreen,
                              icon: Icons.extension_rounded,
                              iconBg: AppColors.surfaceVioletTint,
                              iconColor: AppColors.primaryViolet,
                              footerText: 'Chrome • Brave',
                              onTap: _openExtensionSheet,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildHeroCard(
                              title: 'Secure Vault',
                              subtitle: 'AES-256 Storage',
                              badgeText: DashboardService.isVaultUnlocked ? 'Unlocked' : 'Locked',
                              badgeColor: DashboardService.isVaultUnlocked ? AppColors.fabGreen : Colors.orange,
                              icon: DashboardService.isVaultUnlocked ? Icons.lock_open_rounded : Icons.shield_rounded,
                              iconBg: const Color(0xFFFFFBEB),
                              iconColor: const Color(0xFFD97706),
                              footerText: '${vaultItems.length} private items',
                              onTap: _openVaultSheet,
                            ),
                          ),
                        ],
                      ).animate().fade(duration: 300.ms, delay: 100.ms).slideY(begin: 0.05, duration: 300.ms),

                      const SizedBox(height: 22),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tools & Collaboration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          InkWell(
                            onTap: _openAllSavedLinks,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Saved Links ($totalSavedLinks)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 3 Stacked Horizontal Cards (Figma Node 5-2928)
                      _buildFeatureTile(
                        icon: Icons.alarm_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Smart Reminder & Todo',
                        subtitle: '$pendingReminders tasks pending • Due dates & alarms',
                        trailingBadge: pendingReminders > 0 ? '$pendingReminders Due' : 'All Clear',
                        trailingBadgeColor: pendingReminders > 0 ? Colors.red : AppColors.fabGreen,
                        onTap: _openRemindersSheet,
                      ).animate().fade(duration: 250.ms, delay: 150.ms).slideY(begin: 0.05, duration: 250.ms),

                      const SizedBox(height: 12),

                      _buildFeatureTile(
                        icon: Icons.share_rounded,
                        iconBg: const Color(0xFFF0FDF4),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Link Sharing & QR Hub',
                        subtitle: '${sharedBundles.length} shared bundles • Web links & QR codes',
                        trailingBadge: 'Share',
                        trailingBadgeColor: AppColors.primaryViolet,
                        onTap: _openSharingSheet,
                      ).animate().fade(duration: 250.ms, delay: 200.ms).slideY(begin: 0.05, duration: 250.ms),

                      const SizedBox(height: 12),

                      _buildFeatureTile(
                        icon: Icons.groups_rounded,
                        iconBg: const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Team Workspace',
                        subtitle: '${teamMembers.length} collaborators • Multi-seat permissions',
                        trailingBadge: 'PRO',
                        trailingBadgeColor: const Color(0xFFD97706),
                        onTap: _openTeamSheet,
                      ).animate().fade(duration: 250.ms, delay: 250.ms).slideY(begin: 0.05, duration: 250.ms),

                      const SizedBox(height: 16),

                      // Saved Links Quick Access Banner
                      _buildSavedLinksBanner(totalSavedLinks)
                          .animate()
                          .fade(duration: 250.ms, delay: 300.ms),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0),
        child: WorkspaceFab(
          onPressed: _showAddLinkSheet,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String activeUser, int totalSavedLinks, int totalWorkspaces) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar with Online Badge
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryViolet,
                child: Text(
                  activeUser.isNotEmpty ? activeUser[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.fabGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Greeting & Workspace Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hi, $activeUser',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cardTitle,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.yellowButtonText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalWorkspaces Workspaces • $totalSavedLinks Links',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cardSubtitle,
                  ),
                ),
              ],
            ),
          ),
          // Cloud Sync Button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CloudSyncScreen()),
                );
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GoogleDriveSyncService.isConnected ? const Color(0xFFE8F5E9) : AppColors.surfaceVioletTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  GoogleDriveSyncService.isConnected ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                  color: GoogleDriveSyncService.isConnected ? const Color(0xFF2E7D32) : AppColors.primaryViolet,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quick Action / Search Button
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _openAllSavedLinks,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVioletTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primaryViolet,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsRow(int pendingReminders, int vaultCount, int shareCount) {
    return Row(
      children: [
        _buildMetricPill(
          icon: Icons.extension_rounded,
          label: 'Extension',
          statusColor: AppColors.fabGreen,
          onTap: _openExtensionSheet,
        ),
        const SizedBox(width: 8),
        _buildMetricPill(
          icon: Icons.alarm_rounded,
          label: '$pendingReminders Tasks',
          statusColor: pendingReminders > 0 ? Colors.red : AppColors.fabGreen,
          onTap: _openRemindersSheet,
        ),
        const SizedBox(width: 8),
        _buildMetricPill(
          icon: Icons.shield_rounded,
          label: '$vaultCount Vault',
          statusColor: DashboardService.isVaultUnlocked ? AppColors.fabGreen : Colors.orange,
          onTap: _openVaultSheet,
        ),
        const SizedBox(width: 8),
        _buildMetricPill(
          icon: Icons.share_rounded,
          label: '$shareCount Shares',
          statusColor: AppColors.primaryViolet,
          onTap: _openSharingSheet,
        ),
      ],
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: AppColors.primaryViolet),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cardTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String footerText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 144,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cardTitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.cardSubtitle,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 12, color: badgeColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    footerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cardSubtitle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailingBadge,
    required Color trailingBadgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cardTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.cardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: trailingBadgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trailingBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: trailingBadgeColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.iconMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLinksBanner(int totalSavedLinks) {
    return InkWell(
      onTap: _openAllSavedLinks,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6F3CF8), Color(0xFF5619F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bookmarks_rounded, color: AppColors.accentYellow, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Saved Bookmarks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Browse and filter all $totalSavedLinks saved items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textOnPurpleMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Open View',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.yellowButtonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
