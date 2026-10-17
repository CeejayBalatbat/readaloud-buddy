import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/current_learner.dart';
import 'app/feedback_mode.dart';
import 'app/hint_mode.dart';
import 'data/story_providers.dart';
import 'speech/speech_providers.dart';
import 'speech/vosk_health.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/theme/app_colors.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/buddy.dart';

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
      home: const AppStart(),
    );
  }
}

/// First screen: reader setup if nobody is set up yet, otherwise Home.
class AppStart extends ConsumerWidget {
  const AppStart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const splash = Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(child: Buddy(size: 120)),
    );
    // Load the parent's settings before any story can open.
    bool loaded(AsyncValue<Object?> v) => v.hasValue || v.hasError;
    if (!loaded(ref.watch(speechModeProvider)) ||
        !loaded(ref.watch(hintModeProvider)) ||
        !loaded(ref.watch(feedbackModeProvider)) ||
        !loaded(ref.watch(phonicsProvider)) ||
        !loaded(ref.watch(voskMissingWordsProvider)) ||
        !loaded(ref.watch(voskHealthProvider))) {
      return splash;
    }
    return ref.watch(currentLearnerProvider).when(
          loading: () => splash,
          error: (e, _) => Scaffold(body: Center(child: Text('Something went wrong: $e'))),
          data: (learner) => learner == null
              ? SetupScreen(onCreated: (l) => afterSetup(context, l))
              : const HomeShell(),
        );
  }
}
