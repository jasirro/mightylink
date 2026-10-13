import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linku/models/group.dart';
import 'package:linku/theme/app_colors.dart';
import 'package:linku/widgets/linku_bottom_nav.dart';
import 'package:linku/widgets/linku_header.dart';
import 'package:linku/widgets/workspace_card.dart';
import 'package:linku/widgets/workspace_fab.dart';

void main() {
  testWidgets('LinkuHeader renders branding, titles, and actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LinkuHeader(),
        ),
      ),
    );

    expect(find.text('Linku'), findsOneWidget);
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Manage your ideas'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });

  testWidgets('WorkspaceCard renders title, count, folder icon and popup menu', (WidgetTester tester) async {
    final group = Group(
      id: 'g1',
      name: 'flutter',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceCard(
            group: group,
            itemCount: 4,
          ),
        ),
      ),
    );

    expect(find.text('flutter'), findsOneWidget);
    expect(find.text('4 items'), findsOneWidget);
    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
  });

  testWidgets('WorkspaceFab renders add icon and reacts to tap', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: WorkspaceFab(
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    expect(pressed, isTrue);
  });

  testWidgets('LinkuBottomNav highlights Files in red when index is 2', (WidgetTester tester) async {
    int selected = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LinkuBottomNav(
            currentIndex: selected,
            onItemSelected: (idx) => selected = idx,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);

    final filesTextWidget = tester.widget<Text>(find.text('Files'));
    expect(filesTextWidget.style?.color, AppColors.navActiveRed);
  });
}
