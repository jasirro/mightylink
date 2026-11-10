import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/saved_link.dart';
import 'package:intl/intl.dart';
import 'add_link_screen.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';

class LinkDetailsScreen extends StatelessWidget {
  final SavedLink link;

  const LinkDetailsScreen({super.key, required this.link});

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.parse(link.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${link.url}'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SavedLink>>(
      valueListenable: DbService.linksBox.listenable(),
      builder: (context, linksBox, _) {
        final currentLink = linksBox.get(link.id);
        
        if (currentLink == null) {
          return Scaffold(
            backgroundColor: AppColors.primaryViolet,
            appBar: AppBar(iconTheme: const IconThemeData(color: Colors.white)),
            body: const Center(
              child: Text(
                'Link no longer exists',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        }

        final groupsBox = DbService.groupsBox;
        final group = groupsBox.get(currentLink.groupId) ?? groupsBox.values.first;

        return Scaffold(
          backgroundColor: AppColors.primaryViolet,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Link Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  currentLink.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: currentLink.isFavorite ? Colors.redAccent : Colors.white,
                ),
                onPressed: () async {
                  currentLink.isFavorite = !currentLink.isFavorite;
                  await currentLink.save();
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddLinkScreen(existingLink: currentLink),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                onPressed: () {
                  _showDeleteDialog(context, currentLink);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pure White Main Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [AppColors.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVioletTint,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.link_rounded,
                              size: 36,
                              color: AppColors.primaryViolet,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentLink.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cardTitle,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchUrl(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Text(
                          currentLink.url,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryViolet,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        Icons.folder_rounded,
                        'Workspace',
                        group.name,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Date Saved',
                        DateFormat.yMMMd().format(currentLink.createdAt),
                      ),
                      if (currentLink.note.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.cardTitle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVioletTint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            currentLink.note,
                            style: const TextStyle(color: AppColors.cardTitle, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Sunny Yellow Open Button
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _launchUrl(context),
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text(
                      'Open in Browser',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      foregroundColor: AppColors.yellowButtonText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVioletTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryViolet, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.cardSubtitle,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.cardTitle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, SavedLink linkToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Link?', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cardTitle)),
        content: const Text('Are you sure you want to delete this link?'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.cardSubtitle)),
          ),
          FilledButton(
            onPressed: () async {
              await linkToDelete.delete();
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to list
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
