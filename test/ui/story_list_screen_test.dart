import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/data/story.dart';
import 'package:readaloud_buddy/data/story_providers.dart';
import 'package:readaloud_buddy/ui/screens/story_list_screen.dart';

void main() {
  testWidgets('shows story titles with level and language chips', (
    tester,
  ) async {
    const fake = [
      Story(
        id: 'S01',
        title: 'Sam and the Cat',
        language: 'EN',
        level: 1,
        text: '',
        words: [],
        questions: [],
      ),
      Story(
        id: 'S04',
        title: 'Ang Bola ni Ana',
        language: 'FIL',
        level: 1,
        text: '',
        words: [],
        questions: [],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storiesProvider.overrideWith((ref) async => fake)],
        // Plain theme here: the app theme uses google_fonts, which would try to
        // download fonts during the test.
        child: const MaterialApp(home: StoryListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sam and the Cat'), findsOneWidget);
    expect(find.text('Ang Bola ni Ana'), findsOneWidget);
    expect(find.text('Filipino'), findsOneWidget);
    expect(find.text('Level 1'), findsNWidgets(2));
  });
}
