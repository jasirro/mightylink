import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import '../services/db_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/linku_header.dart';
import '../widgets/workspace_card.dart';
import '../widgets/workspace_fab.dart';
import 'group_details_screen.dart';
import 'link_details_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
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

  void _showSettingsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'New Workspace',
          style: TextStyle(
            color: AppColors.cardTitle,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.cardTitle),
          decoration: InputDecoration(
            hintText: 'e.g. Design Inspiration, Dev Tools',
            hintStyle: const TextStyle(color: AppColors.cardSubtitle),
            filled: true,
            fillColor: AppColors.surfaceVioletTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.cardSubtitle, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final group = Group(
                  id: const Uuid().v4(),
                  name: controller.text.trim(),
                  createdAt: DateTime.now(),
                );
                await DbService.groupsBox.put(group.id, group);
                GoogleDriveSyncService.scheduleDebouncedSync();
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              foregroundColor: AppColors.yellowButtonText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(BuildContext context, Group group) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit Workspace',
          style: TextStyle(
            color: AppColors.cardTitle,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.cardTitle),
          decoration: InputDecoration(
            hintText: 'Workspace Name',
            hintStyle: const TextStyle(color: AppColors.cardSubtitle),
            filled: true,
            fillColor: AppColors.surfaceVioletTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.cardSubtitle, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                group.name = controller.text.trim();
                await group.save();
                GoogleDriveSyncService.scheduleDebouncedSync();
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              foregroundColor: AppColors.yellowButtonText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Workspace?',
          style: TextStyle(
            color: AppColors.cardTitle,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}" and all its saved links? This cannot be undone.',
          style: const TextStyle(color: AppColors.cardSubtitle, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.cardSubtitle, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () async {
              GoogleDriveSyncService.recordDeletedGroup(group.id);
              await group.delete();
              final linksBox = DbService.linksBox;
              final linksToDelete = linksBox.values.where((l) => l.groupId == group.id).toList();
              for (var link in linksToDelete) {
                GoogleDriveSyncService.recordDeletedLink(link.id);
                await link.delete();
              }
              GoogleDriveSyncService.scheduleDebouncedSync();
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingLinkTile(SavedLink link, Box<Group> groupsBox) {
    final group = groupsBox.get(link.groupId);
    final groupName = group?.name ?? 'Workspace';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LinkDetailsScreen(link: link)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVioletTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.link_rounded, color: AppColors.primaryViolet, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              groupName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.yellowButtonText,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (link.isFavorite)
                            const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.accentYellow),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        link.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cardTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.url,
                        style: const TextStyle(fontSize: 12, color: AppColors.cardSubtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (link.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          link.note,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Box<Group>>(
          valueListenable: DbService.groupsBox.listenable(),
          builder: (context, groupsBox, _) {
            List<Group> allGroups = groupsBox.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ValueListenableBuilder<Box<SavedLink>>(
              valueListenable: DbService.linksBox.listenable(),
              builder: (context, linksBox, _) {
                List<SavedLink> allLinks = linksBox.values.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                List<Group> displayGroups = allGroups;
                List<SavedLink> matchingLinks = [];

                final isFiltered = _searchQuery.isNotEmpty || _selectedFilter != 'All';

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  if (_selectedFilter == 'All' || _selectedFilter == 'Workspaces') {
                    displayGroups = allGroups.where((g) => g.name.toLowerCase().contains(q)).toList();
                  } else {
                    displayGroups = [];
                  }

                  if (_selectedFilter == 'All' || _selectedFilter == 'Links' || _selectedFilter == 'Favorites') {
                    matchingLinks = allLinks.where((l) {
                      if (_selectedFilter == 'Favorites' && !l.isFavorite) return false;
                      return l.title.toLowerCase().contains(q) ||
                             l.url.toLowerCase().contains(q) ||
                             l.note.toLowerCase().contains(q);
                    }).toList();
                  }
                } else if (_selectedFilter == 'Favorites') {
                  displayGroups = [];
                  matchingLinks = allLinks.where((l) => l.isFavorite).toList();
                } else if (_selectedFilter == 'Links') {
                  displayGroups = [];
                  matchingLinks = allLinks;
                } else if (_selectedFilter == 'Workspaces') {
                  displayGroups = allGroups;
                  matchingLinks = [];
                }

                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                    SliverToBoxAdapter(
                      child: LinkuHeader(
                        title: 'Workspaces',
                        subtitle: 'Manage your links',
                        isSearchVisible: _isSearchVisible,
                        searchController: _searchController,
                        selectedFilter: _selectedFilter,
                        onFilterSelected: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        onSearchChanged: _onSearchChanged,
                        onSearchPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchDebounceTimer?.cancel();
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedFilter = 'All';
                            }
                          });
                        },
                        onSettingsPressed: () => _showSettingsDialog(context),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 12),
                    ),
                    if (isFiltered && displayGroups.isEmpty && matchingLinks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          message: 'No matching results',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'No workspaces or links matched "$_searchQuery".'
                              : 'No items match the "$_selectedFilter" filter.',
                        ),
                      )
                    else if (!isFiltered && allGroups.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.create_new_folder_outlined,
                          message: 'No workspaces yet',
                          subtitle: 'Tap the green + button below to create your first workspace.',
                        ),
                      )
                    else ...[
                      if (displayGroups.isNotEmpty) ...[
                        if (matchingLinks.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                              child: Text(
                                'WORKSPACES (${displayGroups.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentYellow,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, matchingLinks.isNotEmpty ? 16 : 110),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.92,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final group = displayGroups[index];
                                final groupLinksCount =
                                    linksBox.values.where((l) => l.groupId == group.id).length;
                                return WorkspaceCard(
                                  group: group,
                                  itemCount: groupLinksCount,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GroupDetailsScreen(
                                          title: group.name,
                                          groupId: group.id,
                                        ),
                                      ),
                                    );
                                  },
                                  onEdit: () => _showEditGroupDialog(context, group),
                                  onDelete: () => _showDeleteGroupDialog(context, group),
                                ).animate().fade(duration: 250.ms).slideY(begin: 0.08, duration: 250.ms, delay: (index * 30).ms);
                              },
                              childCount: displayGroups.length,
                            ),
                          ),
                        ),
                      ],
                      if (matchingLinks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                            child: Text(
                              'MATCHING LINKS (${matchingLinks.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentYellow,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final link = matchingLinks[index];
                                return _buildMatchingLinkTile(link, groupsBox)
                                    .animate()
                                    .fade(duration: 250.ms)
                                    .slideY(begin: 0.06, duration: 250.ms, delay: (index * 25).ms);
                              },
                              childCount: matchingLinks.length,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0),
        child: WorkspaceFab(
          onPressed: () => _showAddGroupDialog(context),
        ),
      ),
    );
  }
}
