import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_link.dart';
import 'link_details_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/saved_link_card.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Favorites',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<SavedLink>>(
        valueListenable: DbService.linksBox.listenable(),
        builder: (context, linksBox, _) {
          final favorites = linksBox.values.where((l) => l.isFavorite).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              message: 'No favorites yet',
              subtitle: 'Mark links with the heart icon to save them to your favorites.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.88,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final link = favorites[index];
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
              );
            },
          );
        },
      ),
    );
  }
}
