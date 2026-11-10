import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_link.dart';
import '../services/db_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/saved_link_card.dart';
import '../widgets/workspace_fab.dart';
import 'add_link_screen.dart';
import 'link_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String title;
  final String groupId;

  const GroupDetailsScreen({
    super.key,
    required this.title,
    required this.groupId,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;
  Timer? _searchDebounceTimer;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
      }
    });
  }

  void _showDeleteDialog(BuildContext context, SavedLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Link?',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cardTitle),
        ),
        content: Text('Are you sure you want to delete "${link.title}"?'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.cardSubtitle)),
          ),
          FilledButton(
            onPressed: () async {
              GoogleDriveSyncService.recordDeletedLink(link.id);
              await link.delete();
              GoogleDriveSyncService.scheduleDebouncedSync();
              if (context.mounted) Navigator.pop(context);
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

  void _showShareDialog(BuildContext context) {
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
              Text(
                'Share "${widget.title}" Workspace',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cardTitle,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Export or copy links in this workspace.',
                style: TextStyle(fontSize: 13, color: AppColors.cardSubtitle),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVioletTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.copy_rounded, color: AppColors.primaryViolet),
                ),
                title: const Text('Copy Workspace Name', style: TextStyle(fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied "${widget.title}" to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLinkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLinkScreen(
        existingLink: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                        if (!_isSearchVisible) {
                          _searchDebounceTimer?.cancel();
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    icon: Icon(
                      _isSearchVisible ? Icons.close : Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showShareDialog(context),
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search inside ${widget.title}...',
                      hintStyle: const TextStyle(color: AppColors.iconMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryViolet),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
            // Content
            Expanded(
              child: ValueListenableBuilder<Box<SavedLink>>(
                valueListenable: DbService.linksBox.listenable(),
                builder: (context, linksBox, _) {
                  List<SavedLink> links = linksBox.values
                      .where((l) => l.groupId == widget.groupId)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (_searchQuery.isNotEmpty) {
                    links = links.where((l) =>
                        l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        l.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        l.note.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                  }

                  if (links.isEmpty) {
                    return EmptyState(
                      icon: Icons.link_off_rounded,
                      message: _searchQuery.isNotEmpty ? 'No matching links' : 'No links in workspace',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Try searching with a different term.'
                          : 'Tap the green + button to save your first link to this workspace.',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return SavedLinkCard(
                        link: link,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LinkDetailsScreen(link: link),
                            ),
                          );
                        },
                        onFavoriteToggle: () async {
                          link.isFavorite = !link.isFavorite;
                          await link.save();
                          GoogleDriveSyncService.scheduleDebouncedSync();
                        },
                        onDelete: () => _showDeleteDialog(context, link),
                      ).animate().fade(duration: 250.ms).slideY(begin: 0.08, duration: 250.ms, delay: (index * 30).ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: WorkspaceFab(
          onPressed: _showAddLinkSheet,
        ),
      ),
    );
  }
}
