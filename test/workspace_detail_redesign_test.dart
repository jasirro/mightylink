import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linku/models/saved_link.dart';
import 'package:linku/theme/app_colors.dart';
import 'package:linku/widgets/saved_link_card.dart';

void main() {
  testWidgets('SavedLinkCard displays date, title, preview box, tag, sparkle, and delete icon', (WidgetTester tester) async {
    final link = SavedLink(
      id: 'l1',
      title: 'State Mgmt',
      url: 'https://flutter.dev/docs/development/data-and-backend/state-mgmt',
      note: 'Riverpod 2.0 guide & cache patterns.',
      groupId: 'g1',
      isFavorite: false,
      createdAt: DateTime(2026, 5, 24),
    );

    bool favoriteToggled = false;
    bool deleteTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedLinkCard(
            link: link,
            onFavoriteToggle: () => favoriteToggled = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      ),
    );

    // Title
    expect(find.text('State Mgmt'), findsOneWidget);
    // Description
    expect(find.text('Riverpod 2.0 guide & cache patterns.'), findsOneWidget);
    // Platform label
    expect(find.text('Flutter Dev'), findsOneWidget);
    // Tag
    expect(find.text('flutter'), findsOneWidget);
    // Date
    expect(find.text('24/5'), findsOneWidget);

    // Link chain icon badge
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);

    // Sparkle icon
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    expect(favoriteToggled, isTrue);

    // Delete icon
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(deleteTapped, isTrue);
  });

  testWidgets('SavedLinkCard displays active purple sparkle when favorite', (WidgetTester tester) async {
    final link = SavedLink(
      id: 'l2',
      title: 'Claude AI',
      url: 'https://claude.ai',
      note: 'Key insight extracted from prompt.',
      groupId: 'g1',
      isFavorite: true,
      createdAt: DateTime(2026, 5, 26),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedLinkCard(link: link),
        ),
      ),
    );

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.auto_awesome));
    expect(iconWidget.color, AppColors.sparklePurple);
  });
}
