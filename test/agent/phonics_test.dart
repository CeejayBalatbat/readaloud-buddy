import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

import 'fixtures.dart';

void main() {
  final phonics =
      PhonicsDictionary.parse(File('assets/data/phonics.json').readAsStringSync());
  final stories =
      parseStories(File('assets/data/stories.json').readAsStringSync());
  final english = stories.where((s) => s.language == 'EN');

  Hint hint(String word, int level) =>
      HintLadder.hintFor(word, level, 'EN', phonics: phonics);
  List<String> say(Hint h) => [for (final p in h.speech) p.tts];

  group('§2 phonics.json (tools/gen_phonics.py)', () {
    test('covers every English story word', () {
      for (final s in english) {
        for (final w in s.words) {
          expect(phonics[w.word], isNotNull, reason: '${s.id} "${w.word}"');
        }
      }
    });

    test('"the" is a sight word', () {
      expect(phonics['the']!.type, WordType.sight);
      expect(phonics['was']!.type, WordType.sight);
      expect(phonics['said']!.type, WordType.sight);
    });

    test('"had": h·a·d = HH AE D, h · ad, hat 🎩', () {
      final e = phonics['had']!;
      expect(e.type, WordType.decodable);
      expect(e.graphemes, ['h', 'a', 'd']);
      expect(e.phonemes, ['HH', 'AE', 'D']);
      expect((e.onset, e.rime), ('h', 'ad'));
      expect((e.keyword, e.emoji), ('hat', '🎩'));
    });

    test('"ship": sh · ip, shoe 👟; "strong": str · ong, string 🧵', () {
      expect(phonics['ship']!.graphemes, ['sh', 'i', 'p']);
      expect((phonics['ship']!.onset, phonics['ship']!.rime), ('sh', 'ip'));
      expect(phonics['ship']!.keyword, 'shoe');
      expect((phonics['strong']!.onset, phonics['strong']!.rime), ('str', 'ong'));
      expect((phonics['strong']!.keyword, phonics['strong']!.emoji), ('string', '🧵'));
    });

    test('silent letters are marked: kite = k·i·t·e(silent)', () {
      expect(phonics['kite']!.graphemes, ['k', 'i', 't', 'e(silent)']);
      expect(phonics['kite']!.phonemes, ['K', 'AY', 'T']);
    });

    test('one keyword per first sound, and never the word itself', () {
      final bySound = <String, Set<String>>{};
      for (final e in phonics.entries) {
        if (e.type == WordType.sight || e.keyword == null) continue;
        expect(e.keyword, isNot(e.word), reason: e.word);
        // The first sound: the onset, or the first vowel ("and" → AE).
        final sound = e.onsetPhonemes.isNotEmpty
            ? e.onsetPhonemes.join(' ')
            : e.phonemes.first.split(' ').first;
        bySound.putIfAbsent(sound, () => {}).add(e.keyword!);
      }
      for (final MapEntry(:key, :value) in bySound.entries) {
        // A second keyword only where the first is the word itself
        // (fish → fox, kite → key).
        expect(value.length, lessThanOrEqualTo(2), reason: '$key: $value');
      }
      expect(phonics['sun']?.keyword ?? phonics['sam']!.keyword, 'sun');
      expect(phonics['then']!.keyword, 'this'); // /ð/, not thumb's /θ/
      expect(phonics['thank']!.keyword, 'thumb');
    });
  });

  group('§2 English hints: keywords, never letter names', () {
    test('sight words get one hint: "This one we just know: the"', () {
      for (final level in [1, 2, 3]) {
        final h = hint('The', level);
        expect(h.sight, isTrue);
        expect(h.level, 3);
        expect(h.parts, ['the']);
        expect(say(h), ['This one we just know.', 'the']);
      }
    });

    test('"had": It starts like hat 🎩 / hat… ad… had / had', () {
      final l1 = hint('had', 1);
      expect(l1.parts, ['h']);
      expect((l1.keyword, l1.emoji), ('hat', '🎩'));
      expect(say(l1), ['It starts like', 'hat']);
      final l2 = hint('had', 2);
      expect(l2.display, 'h · ad');
      expect(say(l2), ['hat', 'ad', 'had']);
      expect(say(hint('had', 3)), ['had']);
    });

    test('"ship" → shoe 👟 + sh · ip; "strong" → string 🧵 + str · ong', () {
      expect(hint('ship', 1).parts, ['sh']);
      expect(hint('ship', 1).emoji, '👟');
      expect(say(hint('ship', 2)), ['shoe', 'ip', 'ship']);
      expect(hint('strong', 2).display, 'str · ong');
      expect(say(hint('strong', 2)), ['string', 'ong', 'strong']);
    });

    test('rimes are said as chunks TTS reads right ("thread" → ed)', () {
      expect(say(hint('thread', 2)), ['three', 'ed', 'thread']);
      expect(say(hint('he', 2)), ['hat', 'ee', 'he']);
    });

    test('a word starting with a vowel: apple 🍎', () {
      final l1 = hint('and', 1);
      expect(l1.parts, ['a']);
      expect(l1.keyword, 'apple');
      expect(say(hint('and', 2)), ['apple', 'and']);
    });

    test('level 1 can play a recorded sound instead of the keyword', () {
      final keyword = hint('had', 1).speech.last;
      expect(keyword.tts, 'hat');
      expect(keyword.clips, ['HH']); // assets/sounds/HH.mp3, if recorded
      expect(hint('strong', 1).speech.last.clips, ['S', 'T', 'R']);
    });

    test('no hint ever says a letter name or a lone sound (every word)', () {
      final loneLetters = RegExp(r'^[a-z]$|^[^aeiouy]+$');
      for (final s in english) {
        for (final w in s.words) {
          for (final level in [1, 2, 3]) {
            final h = hint(w.word, level);
            for (final p in h.speech) {
              final isTheWord = p.tts == WordMatcher.normalize(w.word);
              expect(isTheWord || !loneLetters.hasMatch(p.tts), isTrue,
                  reason: '"${w.word}" level $level says "${p.tts}"');
            }
          }
        }
      }
    });

    test('a word missing from phonics.json still never says letters', () {
      final h1 = HintLadder.hintFor('zap', 1, 'EN');
      expect(say(h1), ['Look at how it starts.']);
      final h2 = HintLadder.hintFor('basket', 2, 'EN');
      expect(say(h2), ['bas', 'ket', 'basket']);
    });

    test('a sight word goes straight to the whole word, then "Next word"', () {
      final t = ReadingTracker(
        words: words('Sam the'),
        language: 'EN',
        phonics: phonics,
        listensForQuiet: false,
      );
      t.onWordHeard('Sam', s(0));
      final h = t.tick(s(5)).hint!;
      expect(h.sight, isTrue);
      expect(t.currentHintLevel, 3);
      expect(t.tick(s(60)).hint, isNull); // no more steps; Buddy waits
    });
  });

  group('§2 Filipino stays syllable-based', () {
    test('ba / ba… ta… bata / bata', () {
      expect(HintLadder.hintFor('bata', 1, 'FIL', phonics: phonics).speech,
          [const SpokenPart('ba')]);
      expect([for (final p in HintLadder.hintFor('bata', 2, 'FIL').speech) p.tts],
          ['ba', 'ta', 'bata']);
      expect([for (final p in HintLadder.hintFor('may', 2, 'FIL').speech) p.tts],
          ['ma', 'may']);
    });
  });
}
