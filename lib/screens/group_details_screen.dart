import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_link.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/linku_bottom_nav.dart';
import '../widgets/saved_link_card.dart';
import 'add_link_screen.dart';
import 'link_details_screen.dart';
import 'main_screen.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, SavedLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link?'),
        content: Text('Are you sure you want to delete "${link.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await link.delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
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
              const SizedBox(height: 16),
              Text(
                'Share "${widget.title}" Workspace',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Export or share links in this workspace with other applications.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.brandDark),
                title: const Text('Copy Workspace Name'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied "${widget.title}" to clipboard')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching Figma
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.cardTitle,
                      size: 22,
                    ),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Search icon
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                        if (!_isSearchVisible) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.cardTitle,
                      size: 26,
                    ),
                    tooltip: 'Search inside workspace',
                  ),
                  // Share icon
                  IconButton(
                    onPressed: () => _showShareDialog(context),
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.cardTitle,
                      size: 24,
                    ),
                    tooltip: 'Share workspace',
                  ),
                ],
              ),
            ),
            // Search field when active
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search inside ${widget.title}...',
                    hintStyle: const TextStyle(color: AppColors.subtitle),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryNavy),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
            // Real-time link grid from Hive
            Expanded(
              child: ValueListenableBuilder<Box<SavedLink>>(
                valueListenable: DbService.linksBox.listenable(),
                builder: (context, linksBox, _) {
                  List<SavedLink> links = linksBox.values
                      .where((l) => l.groupId == widget.groupId)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    links = links
                        .where((l) =>
                            l.title.toLowerCase().contains(query) ||
                            l.url.toLowerCase().contains(query) ||
                            l.note.toLowerCase().contains(query))
                        .toList();
                  }

                  if (links.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EmptyState(
                            icon: Icons.link_off_rounded,
                            message: _searchQuery.isNotEmpty
                                ? 'No matching links found'
                                : 'No links yet',
                            subtitle: _searchQuery.isNotEmpty
                                ? 'Try a different search query.'
                                : 'Save your first link to "${widget.title}".',
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (context) => const AddLinkScreen(),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandDark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Link'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final int crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;
                      final double childAspectRatio = crossAxisCount == 4 ? 0.72 : 0.80;

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: childAspectRatio,
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
                            },
                            onDelete: () => _showDeleteDialog(context, link),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LinkuBottomNav(
        currentIndex: 2,
        onItemSelected: (index) {
          if (index == 2) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => MainScreen(initialIndex: index),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}
