import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import 'link_details_screen.dart';
import 'add_link_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/saved_link_card.dart';
import '../widgets/workspace_fab.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0: All, 1: Favorites, 2: Recent
  bool _isSearchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddLinkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLinkScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Box<SavedLink>>(
          valueListenable: DbService.linksBox.listenable(),
          builder: (context, linksBox, _) {
            return ValueListenableBuilder<Box<Group>>(
              valueListenable: DbService.groupsBox.listenable(),
              builder: (context, groupsBox, _) {
                List<SavedLink> allLinks = linksBox.values.toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                List<SavedLink> displayLinks = List.from(allLinks);
                if (_selectedFilter == 1) {
                  displayLinks = displayLinks.where((l) => l.isFavorite).toList();
                } else if (_selectedFilter == 2) {
                  displayLinks = displayLinks.take(8).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  displayLinks = displayLinks.where((l) =>
                      l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      l.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      l.note.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    // Header Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Links',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isSearchVisible = !_isSearchVisible;
                                        if (!_isSearchVisible) {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        }
                                      });
                                    },
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: _isSearchVisible
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isSearchVisible ? Icons.close : Icons.search_rounded,
                                        color: _isSearchVisible
                                            ? AppColors.primaryViolet
                                            : Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${allLinks.length} items saved',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textOnPurpleMuted,
                              ),
                            ),
                            if (_isSearchVisible) ...[
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1F000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(
                                      color: AppColors.cardTitle, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    hintText: 'Search links...',
                                    hintStyle: TextStyle(
                                        color: AppColors.iconMuted, fontWeight: FontWeight.normal),
                                    prefixIcon: Icon(Icons.search_rounded,
                                        color: AppColors.primaryViolet),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.trim();
                                    });
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            // Filter Pills
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip(0, 'All Links', allLinks.length),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    1,
                                    'Favorites',
                                    allLinks.where((l) => l.isFavorite).length,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    2,
                                    'Recent',
                                    allLinks.length > 8 ? 8 : allLinks.length,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    if (displayLinks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.link_off_rounded,
                          message: _searchQuery.isNotEmpty
                              ? 'No matching links'
                              : (_selectedFilter == 1
                                  ? 'No favorites yet'
                                  : 'No saved links yet'),
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try searching with a different term.'
                              : 'Tap the green + button below to save your first link.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.88,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final link = displayLinks[index];
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
                                onDelete: () async {
                                  await link.delete();
                                },
                              ).animate().fade(duration: 250.ms).slideY(begin: 0.08, duration: 250.ms, delay: (index * 30).ms);
                            },
                            childCount: displayLinks.length,
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72.0),
        child: WorkspaceFab(
          onPressed: _showAddLinkSheet,
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryViolet : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceVioletTint
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? AppColors.primaryViolet : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
