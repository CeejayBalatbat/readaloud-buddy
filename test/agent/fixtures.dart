import 'dart:io';

import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

/// Reads a CSV from docs/dataset/ as a list of {column: value} rows.
/// Handles quoted fields with commas ("EN-TH, EN-VT").
List<Map<String, String>> readCsv(String name) {
  final lines = File('docs/dataset/$name')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final header = _splitCsvLine(lines.first);
  return [
    for (final line in lines.skip(1))
      Map.fromIterables(header, _splitCsvLine(line)),
  ];
}

List<String> _splitCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (c == ',' && !quoted) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  out.add(buf.toString());
  return out;
}

/// Word results as written in Word_Events.csv.
WordResult resultFromCsv(String label) => switch (label) {
      'Correct' => WordResult.correct,
      'Hesitated' => WordResult.hesitated,
      'Correct after hint' => WordResult.correctAfterHint,
      'Misread' => WordResult.misread,
      'Skipped' => WordResult.skipped,
      'Unsure (ASR)' => WordResult.unsure,
      _ => throw ArgumentError(label),
    };

/// Builds story words from plain text, e.g. words('The cat sat').
List<StoryWord> words(String text, {List<String> patterns = const ['EN-SV']}) {
  final parts = text.split(' ');
  return [
    for (var i = 0; i < parts.length; i++)
      StoryWord(
        position: i + 1,
        word: parts[i],
        patterns: patterns,
        primaryPattern: patterns.first,
        syllables: 1,
        difficulty: 0.1,
      ),
  ];
}

WordOutcome outcome(
  String word,
  WordResult result, {
  List<String> patterns = const ['EN-SV'],
  int hintLevel = 0,
  int position = 1,
}) =>
    WordOutcome(
      position: position,
      word: word,
      patterns: patterns,
      primaryPattern: patterns.first,
      result: result,
      hintLevel: hintLevel,
    );

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

List<Story> loadStories() =>
    parseStories(File('assets/data/stories.json').readAsStringSync());
