import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/story_list_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  // ProviderScope holds all Riverpod state for the app.
  runApp(const ProviderScope(child: ReadAloudBuddyApp()));
}

class ReadAloudBuddyApp extends StatelessWidget {
  const ReadAloudBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadAloud Buddy',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const StoryListScreen(),
    );
  }
}
