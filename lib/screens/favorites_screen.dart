import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import 'link_details_screen.dart';
import '../widgets/empty_state.dart';
import '../services/db_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: ValueListenableBuilder<Box<SavedLink>>(
        valueListenable: DbService.linksBox.listenable(),
        builder: (context, linksBox, _) {
          final favorites = linksBox.values.where((l) => l.isFavorite).toList();

          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              message: 'No favorites yet',
              subtitle: 'Mark links as favorite to see them here.',
            );
          }

          return ValueListenableBuilder<Box<Group>>(
            valueListenable: DbService.groupsBox.listenable(),
            builder: (context, groupsBox, _) {
              final groups = groupsBox.values.toList();
              
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final link = favorites[index];
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
                    trailing: IconButton(
                      icon: Icon(Icons.favorite, color: theme.colorScheme.primary),
                      onPressed: () async {
                        link.isFavorite = !link.isFavorite;
                        await link.save();
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
                  );
                },
              ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
