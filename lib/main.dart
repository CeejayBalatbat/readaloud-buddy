import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/current_learner.dart';
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
    return ref.watch(currentLearnerProvider).when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: Buddy(size: 120)),
          ),
          error: (e, _) => Scaffold(body: Center(child: Text('Something went wrong: $e'))),
          data: (learner) => learner == null
              ? SetupScreen(onCreated: (l) => afterSetup(context, l))
              : const HomeShell(),
        );
  }
}
