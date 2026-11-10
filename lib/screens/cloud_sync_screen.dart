import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/db_service.dart';
import '../services/dashboard_service.dart';
import '../services/google_drive_sync_service.dart';
import '../models/group.dart';
import '../theme/app_colors.dart';
import 'package:uuid/uuid.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    GoogleDriveSyncService.syncNotifier.addListener(_onSyncUpdate);
  }

  @override
  void dispose() {
    GoogleDriveSyncService.syncNotifier.removeListener(_onSyncUpdate);
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) setState(() {});
  }

  void _handleSync() async {
    try {
      await GoogleDriveSyncService.syncToGoogleSheets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Two-way sync completed successfully!'),
              ],
            ),
            backgroundColor: AppColors.fabGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.deleteRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _connectAccount() async {
    setState(() => _isConnecting = true);
    try {
      final account = await GoogleDriveSyncService.connectGoogleAccount();
      if (account != null && mounted) {
        _handleSync();
      }
    } catch (e) {
      if (mounted) {
        final errString = e.toString();
        if (errString.contains('ApiException: 10') || errString.contains('10:')) {
          _showGoogleSetupDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error: $e'),
              backgroundColor: AppColors.deleteRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _showGoogleSetupDialog(BuildContext context) {
    const packageName = 'com.linku.linku';
    const sha1 = '06:85:8C:61:C8:33:A0:8E:80:9F:66:4C:F9:10:A6:4D:C9:95:EB:F0';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryViolet, size: 26),
            SizedBox(width: 10),
            Text(
              'Google Setup Needed',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.cardTitle),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Play Services requires registering your app\'s Package Name & SHA-1 fingerprint in your Google Cloud / Firebase project.',
              style: TextStyle(fontSize: 13, color: AppColors.cardSubtitle),
            ),
            const SizedBox(height: 16),
            const Text('Package Name:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cardTitle)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      packageName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryViolet,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryViolet),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy Package Name',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: packageName));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package name copied!')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Debug SHA-1 Fingerprint:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cardTitle)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      sha1,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryViolet),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Copy SHA-1',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: sha1));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SHA-1 copied!')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              foregroundColor: AppColors.yellowButtonText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openSheetInBrowser() async {
    final url = GoogleDriveSyncService.spreadsheetUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open spreadsheet URL in browser')),
        );
      }
    }
  }

  void _createEmailWorkspace() {
    final groupsBox = DbService.groupsBox;
    final existing = groupsBox.values.any((g) => g.name.toLowerCase() == 'email inbox');
    if (existing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"Email Inbox" workspace already exists!')),
      );
      return;
    }

    final newGroup = Group(
      id: const Uuid().v4(),
      name: 'Email Inbox',
      createdAt: DateTime.now(),
    );
    groupsBox.put(newGroup.id, newGroup);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Created "Email Inbox" workspace!'),
          ],
        ),
        backgroundColor: AppColors.primaryViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = GoogleDriveSyncService.isConnected;
    final isSyncing = GoogleDriveSyncService.isSyncing;
    final email = GoogleDriveSyncService.connectedEmail;
    final name = GoogleDriveSyncService.connectedName;
    final photo = GoogleDriveSyncService.connectedPhoto;
    final sheetUrl = GoogleDriveSyncService.spreadsheetUrl;
    final lastSync = GoogleDriveSyncService.lastSyncTime;

    final totalLinks = DbService.linksBox.values.length;
    final totalGroups = DbService.groupsBox.values.length;
    final totalReminders = DashboardService.getReminders().length;
    final totalVault = DashboardService.getVaultItems().length;

    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      appBar: AppBar(
        title: const Text('Personal Cloud Sync'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Google Account Card
              _buildAccountCard(isConnected, name, email, photo),

              const SizedBox(height: 18),

              // Personal Google Sheet Card
              if (isConnected) ...[
                _buildSheetInfoCard(sheetUrl, lastSync),
                const SizedBox(height: 18),
                _buildAutoSyncCard(),
                const SizedBox(height: 18),
              ],

              // Sync Metrics
              _buildMetricsGrid(totalLinks, totalGroups, totalReminders, totalVault),

              const SizedBox(height: 20),

              // Primary Sync Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : (isConnected ? _handleSync : _connectAccount),
                  icon: isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.yellowButtonText),
                        )
                      : Icon(
                          isConnected ? Icons.sync_rounded : Icons.login_rounded,
                          color: AppColors.yellowButtonText,
                        ),
                  label: Text(
                    isSyncing
                        ? 'Synchronizing...'
                        : (isConnected ? 'Sync Now (Two-Way Merge)' : 'Connect Google Drive Account'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellowButtonText,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Email & Gmail Sync Card (Safe Solution)
              _buildEmailWorkflowCard(),

              const SizedBox(height: 18),

              // Privacy Notice Card
              _buildPrivacyNoticeCard(),

              if (isConnected) ...[
                const SizedBox(height: 18),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Disconnect Google Account?'),
                          content: const Text(
                            'Your local links and workspaces will remain safely on this device. Cloud sync will pause until you reconnect.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await GoogleDriveSyncService.disconnectGoogleAccount();
                      }
                    },
                    icon: const Icon(Icons.link_off_rounded, size: 16, color: Colors.white70),
                    label: const Text(
                      'Disconnect Google Account',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(bool isConnected, String name, String email, String photo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surfaceVioletTint,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.account_circle_rounded, size: 44, color: AppColors.primaryViolet)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isConnected ? (name.isNotEmpty ? name : 'Google User') : 'Google Account',
                        style: const TextStyle(
                          fontSize: 16,
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
                        color: isConnected ? const Color(0xFFDCFCE7) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isConnected ? 'CONNECTED' : 'DISCONNECTED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isConnected ? const Color(0xFF15803D) : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isConnected ? email : 'Sign in to auto-sync your links to personal Google Drive',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.cardSubtitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isConnected)
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildSheetInfoCard(String sheetUrl, DateTime? lastSync) {
    final syncFormatted = lastSync != null
        ? DateFormat('MMM d, h:mm a').format(lastSync)
        : 'Never synced';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.table_chart_rounded, color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MightyLink_Database',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    Text(
                      'Last Synced: $syncFormatted',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cardSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Color(0xFF15803D)),
                  SizedBox(width: 6),
                  Text(
                    'Stored in your personal Drive',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                  ),
                ],
              ),
              if (sheetUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: _openSheetInBrowser,
                  icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryViolet),
                  label: const Text(
                    'Open in Google Sheets',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryViolet),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSyncCard() {
    final isAutoSync = GoogleDriveSyncService.isAutoSyncEnabled;
    final interval = GoogleDriveSyncService.autoSyncIntervalMinutes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVioletTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.autorenew_rounded, color: AppColors.primaryViolet, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Background Sync',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Continuous background sync worker',
                      style: TextStyle(fontSize: 12, color: AppColors.cardSubtitle),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAutoSync,
                activeThumbColor: AppColors.primaryViolet,
                activeTrackColor: AppColors.accentYellow,
                onChanged: (val) async {
                  await GoogleDriveSyncService.setAutoSyncEnabled(val);
                  setState(() {});
                },
              ),
            ],
          ),
          if (isAutoSync) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F5)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periodic Interval',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.cardTitle),
                    ),
                    Text(
                      'Sync frequency while app is active',
                      style: TextStyle(fontSize: 11, color: AppColors.cardSubtitle),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVioletTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<int>(
                    value: interval,
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryViolet),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('Every 5 min')),
                      DropdownMenuItem(value: 15, child: Text('Every 15 min')),
                      DropdownMenuItem(value: 30, child: Text('Every 30 min')),
                      DropdownMenuItem(value: 60, child: Text('Every 1 hour')),
                    ],
                    onChanged: (newVal) async {
                      if (newVal != null) {
                        await GoogleDriveSyncService.setAutoSyncInterval(newVal);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: AppColors.primaryViolet),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-syncs immediately on link edits & when returning from browser or extension.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.primaryViolet, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int links, int workspaces, int reminders, int vault) {
    return Row(
      children: [
        _buildMetricPill('Links', '$links', Icons.bookmark_rounded, AppColors.primaryViolet),
        const SizedBox(width: 8),
        _buildMetricPill('Workspaces', '$workspaces', Icons.folder_rounded, const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        _buildMetricPill('Reminders', '$reminders', Icons.alarm_rounded, AppColors.fabGreen),
        const SizedBox(width: 8),
        _buildMetricPill('Vault', '$vault', Icons.shield_rounded, const Color(0xFFD97706)),
      ],
    );
  }

  Widget _buildMetricPill(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.cardSubtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailWorkflowCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Links from Gmail',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    Text(
                      'Zero-risk 1-click capture from any email',
                      style: TextStyle(fontSize: 12, color: AppColors.cardSubtitle),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'In Gmail on Android or Desktop, tap 3 dots > "Share" > "MightyLink" to bookmark links and articles instantly. Safe, private, and requiring zero dangerous inbox permissions.',
            style: TextStyle(fontSize: 12, color: AppColors.cardSubtitle, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _createEmailWorkspace,
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryViolet),
              label: const Text(
                'Create "Email Inbox" Workspace',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryViolet),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDD6FE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.accentYellow, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your data is stored exclusively in your personal Google Drive account. MightyLink has no central servers and never reads your personal files.',
              style: TextStyle(fontSize: 11, color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
