import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/db_service.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';

class ExtensionSheet extends StatefulWidget {
  const ExtensionSheet({super.key});

  @override
  State<ExtensionSheet> createState() => _ExtensionSheetState();
}

class _ExtensionSheetState extends State<ExtensionSheet> {
  bool _copied = false;
  bool _copiedEmail = false;

  void _copyToken() {
    Clipboard.setData(ClipboardData(text: DashboardService.extensionToken));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Extension Pairing Key copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.primaryViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    setState(() => _copiedEmail = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Account email copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.primaryViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedEmail = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawUser = DbService.activeUser;
    final userEmail = rawUser.contains('@')
        ? rawUser
        : (rawUser.isNotEmpty ? '$rawUser@mightylink.io' : 'alex@mightylink.io');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVioletTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.extension_rounded, color: AppColors.primaryViolet, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browser Extension',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cardTitle,
                        ),
                      ),
                      Text(
                        'Sync bookmarks live from desktop',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.cardSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.iconMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Connection Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.fabGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extension Service Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Text(
                          'Chrome & Brave connected • Real-time Sync',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.fabGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'v1.4',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Email Account Connection (Primary / Recommended)
            const Text(
              'Connected Email Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.cardTitle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVioletTint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryViolet,
                        child: Text(
                          userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MightyLink Account',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cardSubtitle),
                            ),
                            Text(
                              userEmail,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryViolet),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _copyEmail(userEmail),
                        icon: Icon(_copiedEmail ? Icons.check_rounded : Icons.copy_rounded, size: 14),
                        label: Text(_copiedEmail ? 'Copied' : 'Copy Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryViolet,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in with this email in your desktop browser extension to automatically sync all your workspaces and bookmarks.',
                    style: TextStyle(fontSize: 12, color: AppColors.cardSubtitle, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pairing Token Box (Alternative)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Backup Pairing Key',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardSubtitle,
                  ),
                ),
                InkWell(
                  onTap: _copyToken,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          DashboardService.extensionToken,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.primaryViolet,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 13,
                          color: AppColors.primaryViolet,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // How it works steps
            const Text(
              'How to Connect in 3 Steps',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.cardTitle,
              ),
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              '1',
              'Load Extension in Browser',
              'Install from the extension/ folder in Chrome, Brave, or Edge.',
            ),
            const SizedBox(height: 10),
            _buildStepRow(
              '2',
              'Sign in with your Email',
              'Enter $userEmail to immediately link your account.',
            ),
            const SizedBox(height: 10),
            _buildStepRow(
              '3',
              '1-Click Workspace Sync',
              'Press Alt + S on any tab to save links directly into your MightyLink account.',
            ),
            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      backgroundColor: Colors.white,
                      title: const Row(
                        children: [
                          Icon(Icons.extension_rounded, color: AppColors.primaryViolet),
                          SizedBox(width: 10),
                          Text(
                            'Load Extension',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The extension is built and ready in your project directory:',
                            style: TextStyle(fontSize: 13, color: AppColors.cardSubtitle),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVioletTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.2)),
                            ),
                            child: const SelectableText(
                              'extension/',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryViolet,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '1. Open chrome://extensions in Chrome/Brave/Edge.\n2. Enable "Developer mode" in the top-right.\n3. Click "Load unpacked" and select the extension folder.\n4. Use Alt + S to save any tab!',
                            style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.cardTitle),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryViolet)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.install_desktop_rounded, color: AppColors.yellowButtonText),
                label: const Text(
                  'How to Load in Browser',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.yellowButtonText,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceVioletTint,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.3)),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryViolet,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cardTitle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.cardSubtitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
