import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/export_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _shareApp() {
    // ignore: deprecated_member_use
    Share.share(
      'Check out Linku - the best app to organize your links and workspaces! Download it today.',
    );
  }

  void _rateUs() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.example.linku');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch rate us URL');
    }
  }

  void _logout(BuildContext context) async {
    final authBox = Hive.box('auth');
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    await authBox.put('isLoggedIn', false);
    await authBox.put('currentUser', '');
  }

  @override
  Widget build(BuildContext context) {
    final authBox = Hive.box('auth');
    final currentUser = authBox.get('currentUser', defaultValue: '') as String;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.logoBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: AppColors.brandDark, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.isNotEmpty ? currentUser : 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Linku Pro Member',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: AppColors.deleteRed),
                    tooltip: 'Log Out',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                icon: Icons.share,
                iconColor: AppColors.primaryNavy,
                title: 'Share App',
                subtitle: 'Invite friends to use Linku',
                onTap: _shareApp,
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.star_rate_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Rate Us',
                subtitle: 'Leave a review on the App Store',
                onTap: _rateUs,
              ),
              
              const SizedBox(height: 32),
              const Text(
                'Backup & Restore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                icon: Icons.cloud_download_outlined,
                iconColor: AppColors.fabGreen,
                title: 'Export Backup',
                subtitle: 'Save a copy of your data (PDF, Excel, JSON)',
                onTap: () {
                  _showExportOptions(context);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.cloud_upload,
                iconColor: Colors.blue,
                title: 'Upload to Google Sheets',
                subtitle: 'Sync your database to your personal Google Drive',
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting upload...')),
                  );
                  try {
                    await GoogleDriveSyncService.syncToGoogleSheets();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upload successful!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(
                icon: Icons.cloud_download,
                iconColor: AppColors.brandDark,
                title: 'Restore from Google Sheets',
                subtitle: 'Fetch database from your Google Drive',
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting restore...')),
                  );
                  try {
                    await GoogleDriveSyncService.fetchFromGoogleSheets();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restore successful!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
            ].animate(interval: 50.ms).fade(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms),
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
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
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await ExportService.exportAsPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_view, color: AppColors.fabGreen),
                title: const Text('Export as Excel'),
                onTap: () async {
                  Navigator.pop(context);
                  await ExportService.exportAsExcel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_object, color: Colors.blue),
                title: const Text('Export JSON Backup'),
                onTap: () async {
                  Navigator.pop(context);
                  await ExportService.exportAsJson();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cardTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.cardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}
