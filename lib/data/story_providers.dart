import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/phonics.dart';
import '../agent/prediction.dart';
import 'sound_patterns.dart';
import 'story.dart';

const storiesAssetPath = 'assets/data/stories.json';

/// All stories, loaded once from the app's bundled assets.
final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final jsonText = await rootBundle.loadString(storiesAssetPath);
  return parseStories(jsonText);
});

const phonicsAssetPath = 'assets/data/phonics.json';

/// How every English story word sounds (keywords, sight words), made by
/// tools/gen_phonics.py.
final phonicsProvider = FutureProvider<PhonicsDictionary>((ref) async {
  final jsonText = await rootBundle.loadString(phonicsAssetPath);
  return PhonicsDictionary.parse(jsonText);
});

const soundPatternsAssetPath = 'assets/data/sound_patterns.json';

/// The sound patterns (names, examples, difficulty), by code.
final soundPatternsProvider = FutureProvider<Map<String, SoundPattern>>((ref) async =>
    parseSoundPatterns(await rootBundle.loadString(soundPatternsAssetPath)));

/// Predicts each book's word accuracy for a learner (AGENT_SPEC §9).
final predictorProvider = FutureProvider<AccuracyPredictor>((ref) async => AccuracyPredictor(
    patternDifficulty: patternDifficulties(await ref.watch(soundPatternsProvider.future))));
