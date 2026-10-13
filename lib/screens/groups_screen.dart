import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/linku_header.dart';
import '../widgets/workspace_card.dart';
import '../widgets/workspace_fab.dart';
import 'group_details_screen.dart';
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
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context) {
    // Navigate to the Settings Screen when gear icon is tapped
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
        title: const Text('Create New Workspace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Workspace Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
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
        title: const Text('Edit Workspace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Workspace Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                group.name = controller.text.trim();
                await group.save();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace?'),
        content: Text('Are you sure you want to delete "${group.name}" and all its saved links? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await group.delete();
              final linksBox = DbService.linksBox;
              final linksToDelete = linksBox.values.where((l) => l.groupId == group.id).toList();
              for (var link in linksToDelete) {
                await link.delete();
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<Box<Group>>(
          valueListenable: DbService.groupsBox.listenable(),
          builder: (context, groupsBox, _) {
            List<Group> groups = groupsBox.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (_searchQuery.isNotEmpty) {
              groups = groups
                  .where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();
            }

            return ValueListenableBuilder<Box<SavedLink>>(
              valueListenable: DbService.linksBox.listenable(),
              builder: (context, linksBox, _) {
                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                    SliverToBoxAdapter(
                      child: LinkuHeader(
                        isSearchVisible: _isSearchVisible,
                        searchController: _searchController,
                        onSearchChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        onSearchPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                              _searchQuery = '';
                            }
                          });
                        },
                        onSettingsPressed: () => _showSettingsDialog(context),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                    if (groups.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.create_new_folder_outlined,
                          message: _searchQuery.isNotEmpty
                              ? 'No matching workspaces'
                              : 'No workspaces yet',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try searching with a different keyword.'
                              : 'Create a workspace to organize your links.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.90,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final group = groups[index];
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
                              ).animate().fade(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms, delay: (index * 50).ms);
                            },
                            childCount: groups.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: WorkspaceFab(
        onPressed: () => _showAddGroupDialog(context),
      ),
    );
  }
}
