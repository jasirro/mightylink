import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:linku/main.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('auth');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Splash screen shows app name', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LinkNestApp());

    // Verify that the splash screen shows 'mightylink'.
    expect(find.text('mightylink'), findsOneWidget);

    // Allow the 2-second delay to finish.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
