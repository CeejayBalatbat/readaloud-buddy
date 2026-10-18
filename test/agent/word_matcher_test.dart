import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

import 'fixtures.dart';

void main() {
  const m = WordMatcher();

  group('§1 Word matching', () {
    test('lowercases and strips punctuation before comparing', () {
      expect(WordMatcher.normalize('Pip!'), 'pip');
      expect(WordMatcher.normalize('"Hello,'), 'hello');
      expect(m.matches('The', 'the', 'EN'), isTrue);
      expect(m.matches('tub,', 'TUB', 'EN'), isTrue);
    });

    test('EN: words with 5+ letters allow one letter off', () {
      expect(m.matches('strong', 'strang', 'EN'), isTrue); // distance 1
      expect(m.matches('through', 'thru', 'EN'), isFalse); // distance 3
      expect(m.matches('happy', 'happi', 'EN'), isTrue);
    });

    test('EN: words shorter than 5 letters need an exact match', () {
      expect(m.matches('cat', 'cap', 'EN'), isFalse);
      expect(m.matches('kite', 'bite', 'EN'), isFalse);
      expect(m.matches('cat', 'cat', 'EN'), isTrue);
    });

    test('FIL: exact match only, even for long words', () {
      expect(m.matches('bata', 'bato', 'FIL'), isFalse);
      expect(m.matches('naglilinis', 'naglilinas', 'FIL'), isFalse);
      expect(m.matches('Bata.', 'bata', 'FIL'), isTrue);
    });

    test('FIL: spelling variants the recognizer writes count as the same word', () {
      for (final (story, heard) in [
        ('lumpia', 'lumpiya'),
        ('leche', 'letse'),
        ('plastik', 'plastic'),
        ('barangay', 'baranggay'),
        ('kuwento', 'kwento'),
        ('Pilipino', 'filipino'),
        ('Bisaya', 'visaya'),
      ]) {
        expect(m.matches(story, heard, 'FIL'), isTrue, reason: '$story / $heard');
      }
      // Real differences stay different.
      expect(m.matches('bata', 'bato', 'FIL'), isFalse);
      expect(m.matches('uso', 'oso', 'FIL'), isFalse);
      expect(m.matches('noon', 'nuon', 'FIL'), isFalse);
      // English is not affected, and the variants can be switched off.
      expect(m.matches('cat', 'kat', 'EN'), isFalse);
      const strict = WordMatcher(AgentConfig(filSpellingVariants: false));
      expect(strict.matches('lumpia', 'lumpiya', 'FIL'), isFalse);
    });

    test('FIL: no word in our Filipino stories turns into another one', () {
      final stories = loadStories().where((s) => s.language == 'FIL');
      final byVariant = <String, Set<String>>{};
      for (final s in stories) {
        for (final w in s.words) {
          final n = WordMatcher.normalize(w.word);
          (byVariant[WordMatcher.filipinoSpelling(n)] ??= {}).add(n);
        }
      }
      for (final e in byVariant.entries) {
        expect(e.value, hasLength(1), reason: '${e.value} would match each other');
      }
    });

    test('Levenshtein distance is computed correctly', () {
      expect(WordMatcher.levenshtein('kitten', 'sitting'), 3);
      expect(WordMatcher.levenshtein('', 'abc'), 3);
      expect(WordMatcher.levenshtein('same', 'same'), 0);
    });

    test('tolerances come from the config', () {
      const strict = WordMatcher(AgentConfig(enMaxEditDistance: 0));
      expect(strict.matches('strong', 'strang', 'EN'), isFalse);
    });
  });
}
