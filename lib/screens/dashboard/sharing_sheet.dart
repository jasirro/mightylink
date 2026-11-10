import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';

class SharingSheet extends StatefulWidget {
  const SharingSheet({super.key});

  @override
  State<SharingSheet> createState() => _SharingSheetState();
}

class _SharingSheetState extends State<SharingSheet> {
  final TextEditingController _bundleTitleController = TextEditingController();
  String _selectedExpiration = 'Never';
  bool _passwordProtected = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _bundleTitleController.dispose();
    super.dispose();
  }

  void _createBundle() {
    if (_bundleTitleController.text.trim().isEmpty) return;
    final randomSlug = (1000 + DateTime.now().millisecond % 9000);
    DashboardService.addSharedBundle(
      SharedBundle(
        id: const Uuid().v4(),
        title: _bundleTitleController.text.trim(),
        shareUrl: 'https://mightylink.app/s/share-$randomSlug',
        linkCount: 5,
        expiresIn: _selectedExpiration,
        views: 0,
        isPasswordProtected: _passwordProtected,
      ),
    );
    _bundleTitleController.clear();
    setState(() => _isCreating = false);
  }

  void _showQrCodeDialog(SharedBundle bundle) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVioletTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.primaryViolet),
              ),
              const SizedBox(height: 16),
              Text(
                bundle.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cardTitle),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan to view this collection on mobile',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              // High-tech QR Pattern visual container
              Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryViolet, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F5619F6),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded, size: 150, color: Colors.grey.shade900),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryViolet,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.link_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                bundle.shareUrl,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryViolet),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundles = DashboardService.getSharedBundles();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
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
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVioletTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.share_rounded, color: AppColors.primaryViolet, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link Sharing & Bundles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    Text(
                      'Share collections via web URLs & QR codes',
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
          const SizedBox(height: 16),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Active Share Bundles (${bundles.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cardTitle),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isCreating = !_isCreating),
                icon: Icon(_isCreating ? Icons.close : Icons.add_link_rounded, size: 16),
                label: Text(_isCreating ? 'Cancel' : 'New Bundle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCreating ? Colors.grey.shade200 : AppColors.primaryViolet,
                  foregroundColor: _isCreating ? AppColors.cardTitle : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Create Form
          if (_isCreating) ...[
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
                  TextField(
                    controller: _bundleTitleController,
                    decoration: const InputDecoration(
                      hintText: 'Bundle Title (e.g. Q4 Marketing Links)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.cardTitle),
                  ),
                  const Divider(height: 12, color: Color(0xFFDDD6FE)),
                  Row(
                    children: [
                      const Text('Expires in: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cardSubtitle)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedExpiration,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryViolet),
                        items: ['Never', '24 Hours', '7 Days', '30 Days']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedExpiration = val);
                        },
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cardSubtitle)),
                          Switch(
                            value: _passwordProtected,
                            activeThumbColor: AppColors.primaryViolet,
                            onChanged: (val) => setState(() => _passwordProtected = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _createBundle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.yellowButtonText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Generate Public Share Link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Bundle List
          Expanded(
            child: ListView.separated(
              itemCount: bundles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bundle = bundles[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVioletTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.folder_shared_rounded, size: 20, color: AppColors.primaryViolet),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bundle.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.cardTitle),
                                ),
                                Text(
                                  '${bundle.linkCount} links • ${bundle.views} views • Expires: ${bundle.expiresIn}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.cardSubtitle),
                                ),
                              ],
                            ),
                          ),
                          if (bundle.isPasswordProtected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_rounded, size: 10, color: Color(0xFFB45309)),
                                  SizedBox(width: 2),
                                  Text('Protected', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 14, color: AppColors.primaryViolet),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                bundle.shareUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryViolet),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showQrCodeDialog(bundle),
                            icon: const Icon(Icons.qr_code_rounded, size: 16, color: AppColors.primaryViolet),
                            label: const Text('QR Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryViolet)),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: bundle.shareUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Share link copied to clipboard!'),
                                  backgroundColor: AppColors.primaryViolet,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryViolet),
                            label: const Text('Copy Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryViolet)),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              // ignore: deprecated_member_use
                              Share.share(
                                'Check out this MightyLink collection: ${bundle.title} - ${bundle.shareUrl}',
                                subject: bundle.title,
                              );
                            },
                            icon: const Icon(Icons.share_rounded, size: 14),
                            label: const Text('Share', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryViolet,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
