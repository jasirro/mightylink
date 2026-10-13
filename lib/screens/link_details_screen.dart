import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
import '../models/saved_link.dart';
import 'package:intl/intl.dart';
import 'add_link_screen.dart';
import '../services/db_service.dart';

class LinkDetailsScreen extends StatelessWidget {
  final SavedLink link;

  const LinkDetailsScreen({super.key, required this.link});

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.parse(link.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${link.url}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Box<SavedLink>>(
      valueListenable: DbService.linksBox.listenable(),
      builder: (context, linksBox, _) {
        final currentLink = linksBox.get(link.id);
        
        if (currentLink == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Link no longer exists')),
          );
        }

        final groupsBox = DbService.groupsBox;
        final group = groupsBox.get(currentLink.groupId) ?? groupsBox.values.first;

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(currentLink.isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () async {
                  currentLink.isFavorite = !currentLink.isFavorite;
                  await currentLink.save();
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => AddLinkScreen(existingLink: currentLink),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _showDeleteDialog(context, currentLink);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      currentLink.title.isNotEmpty ? currentLink.title[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  currentLink.title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _launchUrl(context),
                  child: Text(
                    currentLink.url,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoRow(context, Icons.folder_outlined, 'Group', group.name),
                const SizedBox(height: 16),
                _buildInfoRow(context, Icons.calendar_today_outlined, 'Saved', DateFormat.yMMMd().format(currentLink.createdAt)),
                const SizedBox(height: 32),
                if (currentLink.note.isNotEmpty) ...[
                  Text('Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(currentLink.note, style: theme.textTheme.bodyMedium),
                  ),
                ]
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _launchUrl(context),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open Link'),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, SavedLink linkToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link?'),
        content: const Text('Are you sure you want to delete this link?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await linkToDelete.delete();
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to list
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
