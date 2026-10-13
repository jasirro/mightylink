import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import 'group_details_screen.dart';
import 'link_details_screen.dart';
import 'add_link_screen.dart';
import '../widgets/empty_state.dart';
import '../services/db_service.dart';

import 'settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  int _selectedFilter = 0; // 0: All, 1: Favorites, 2: Recent

  void _showAddLinkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddLinkScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('linku', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<SavedLink>>(
        valueListenable: DbService.linksBox.listenable(),
        builder: (context, linksBox, _) {
          return ValueListenableBuilder<Box<Group>>(
            valueListenable: DbService.groupsBox.listenable(),
            builder: (context, groupsBox, _) {
              final groups = groupsBox.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              List<SavedLink> allLinks = linksBox.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              List<SavedLink> displayLinks = List.from(allLinks);
              if (_selectedFilter == 1) {
                displayLinks = displayLinks.where((l) => l.isFavorite).toList();
              } else if (_selectedFilter == 2) {
                displayLinks = displayLinks.take(5).toList();
              }

              if (_searchQuery.isNotEmpty) {
                displayLinks = displayLinks.where((l) => 
                  l.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                  l.url.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          SearchBar(
                            hintText: 'Search your saved links...',
                            leading: const Icon(Icons.search),
                            elevation: WidgetStateProperty.all(1),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', 0),
                                const SizedBox(width: 8),
                                _buildFilterChip('Favorites', 1),
                                const SizedBox(width: 8),
                                _buildFilterChip('Recent', 2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (groups.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Groups', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: groups.length,
                                itemBuilder: (context, index) {
                                  final group = groups[index];
                                  final groupLinksCount = allLinks.where((l) => l.groupId == group.id).length;
                                  return Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      elevation: 0,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => GroupDetailsScreen(title: group.name, groupId: group.id),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.folder, color: theme.colorScheme.primary),
                                              const SizedBox(height: 8),
                                              Text(
                                                group.name,
                                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$groupLinksCount links',
                                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ).animate().fade(duration: 300.ms).slideX(begin: 0.1, duration: 300.ms, delay: (index * 50).ms);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text('Recent Links', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (displayLinks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.link_off,
                        message: 'No links found',
                        subtitle: 'Try adding a new link or adjust your filters.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final link = displayLinks[index];
                            final group = groups.firstWhere((g) => g.id == link.groupId, orElse: () => groups.first);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                foregroundColor: theme.colorScheme.onPrimaryContainer,
                                child: Text(link.title.isNotEmpty ? link.title[0].toUpperCase() : '?'),
                              ),
                              title: Text(link.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${link.url}\n${group.name}', maxLines: 2, overflow: TextOverflow.ellipsis),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await link.delete();
                                  } else if (value == 'edit') {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (context) => AddLinkScreen(existingLink: link),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LinkDetailsScreen(link: link),
                                  ),
                                );
                              },
                            ).animate().fade(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms, delay: (index * 30).ms);
                          },
                          childCount: displayLinks.length,
                        ),
                      ),
                    ),
                ],
              ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLinkSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = index;
        });
      },
    );
  }
}
