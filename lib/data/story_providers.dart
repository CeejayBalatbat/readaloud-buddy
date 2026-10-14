import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story.dart';

const storiesAssetPath = 'assets/data/stories.json';

/// All 20 stories, loaded once from the app's bundled assets.
final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final jsonText = await rootBundle.loadString(storiesAssetPath);
  return parseStories(jsonText);
});
