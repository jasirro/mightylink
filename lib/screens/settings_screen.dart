import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_colors.dart';
import 'cloud_sync_screen.dart';
import 'login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _shareApp() {
    // ignore: deprecated_member_use
    Share.share(
      'Check out mightylink - the best workspace link manager! Save and organize links effortlessly.',
    );
  }

  void _rateUs() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.example.linku');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch rate us URL');
    }
  }

  void _exportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Export Your Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cardTitle,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Download a backup copy of your saved links and workspaces.',
                style: TextStyle(color: AppColors.cardSubtitle, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                title: const Text('Export as PDF Document', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Nicely formatted document for printing or reading'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () async {
                  Navigator.pop(context);
                  await ExportService.exportAsPdf();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_chart, color: Colors.green),
                ),
                title: const Text('Export as Excel Spreadsheet', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Structured table for data analysis (.xlsx)'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () async {
                  Navigator.pop(context);
                  await ExportService.exportAsExcel();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.code, color: Colors.blue),
                ),
                title: const Text('Export as JSON File', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Raw portable data backup format'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () async {
                  Navigator.pop(context);
                  await ExportService.exportAsJson();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cardTitle),
        ),
        content: const Text(
          'Are you sure you want to log out of mightylink?',
          style: TextStyle(color: AppColors.cardSubtitle),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.cardSubtitle)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authBox = Hive.box('auth');
      await authBox.put('isLoggedIn', false);
      await authBox.put('currentUser', '');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authBox = Hive.box('auth');
    final currentUser = authBox.get('currentUser', defaultValue: 'User') as String;
    final totalLinks = DbService.linksBox.values.length;
    final totalGroups = DbService.groupsBox.values.length;

    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 110.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Settings
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Account, backup & preferences',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textOnPurpleMuted,
                ),
              ),
              const SizedBox(height: 24),

              // User Profile Card (Figma White Rounded Card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVioletTint,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          currentUser.isNotEmpty
                              ? currentUser.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryViolet,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.isNotEmpty ? currentUser : 'Alex Morgan',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cardTitle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVioletTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'mightylink Pro Member',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryViolet,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVioletTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.fabGreen,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms),

              const SizedBox(height: 20),

              // Figma Stats Overview Row (from Figma frame 7)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Links',
                      count: '$totalLinks',
                      icon: Icons.link_rounded,
                      color: AppColors.primaryViolet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Workspaces',
                      count: '$totalGroups',
                      icon: Icons.folder_rounded,
                      color: AppColors.fabGreen,
                    ),
                  ),
                ],
              ).animate().fade(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // Section 1: Cloud & Backups
              _buildSectionTitle('Cloud & Backups'),
              const SizedBox(height: 12),
              _buildSettingsGroup([
                _buildSettingsTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: const Color(0xFF4285F4),
                  title: 'Personal Cloud & Sheets Sync',
                  subtitle: GoogleDriveSyncService.isConnected
                      ? 'Connected: ${GoogleDriveSyncService.connectedEmail}'
                      : 'Connect personal Google Drive & Sheets',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (GoogleDriveSyncService.isConnected)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.fabGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.iconMuted),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CloudSyncScreen()),
                    ).then((_) => setState(() {}));
                  },
                ),
                const Divider(height: 1, indent: 64, endIndent: 20),
                _buildSettingsTile(
                  icon: Icons.download_rounded,
                  iconColor: AppColors.fabGreen,
                  title: 'Export Data',
                  subtitle: 'Save links as PDF document or Excel sheet',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.iconMuted),
                  onTap: () => _exportDialog(context),
                ),
              ]),

              const SizedBox(height: 24),

              // Section 2: App Preferences
              _buildSectionTitle('General & About'),
              const SizedBox(height: 12),
              _buildSettingsGroup([
                _buildSettingsTile(
                  icon: Icons.share_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Share mightylink',
                  subtitle: 'Recommend mightylink to friends or colleagues',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.iconMuted),
                  onTap: _shareApp,
                ),
                const Divider(height: 1, indent: 64, endIndent: 20),
                _buildSettingsTile(
                  icon: Icons.star_rate_rounded,
                  iconColor: const Color(0xFFEAB308),
                  title: 'Rate on Play Store',
                  subtitle: 'Help us grow with a 5-star review',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.iconMuted),
                  onTap: _rateUs,
                ),
                const Divider(height: 1, indent: 64, endIndent: 20),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.primaryViolet,
                  title: 'Version & Build',
                  subtitle: 'mightylink v1.0.0 (Figma Edition)',
                  trailing: const Text(
                    'Latest',
                    style: TextStyle(
                      color: AppColors.fabGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 28),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => _logout(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deleteRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 3,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPurpleMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            count,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.cardTitle,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.cardSubtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cardSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
