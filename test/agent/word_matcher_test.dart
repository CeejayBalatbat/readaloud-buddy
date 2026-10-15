import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';

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
