import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/agent/agent.dart';
import 'package:readaloud_buddy/data/story.dart';

void main() {
  List<String> say(List<SpokenPart> parts) => [for (final p in parts) p.tts];
  List<String?> clips(List<SpokenPart> parts) => [for (final p in parts) p.clip];

  group('§2 Phonics: hints say sounds, not letter names', () {
    test('"had": huh / huh… ad… had / had', () {
      expect(say(HintLadder.hintFor('had', 1, 'EN').speech), ['huh']);
      expect(say(HintLadder.hintFor('had', 2, 'EN').speech), ['huh', 'ad', 'had']);
      expect(say(HintLadder.hintFor('had', 3, 'EN').speech), ['had']);
    });

    test('each sound and rime names its recorded clip', () {
      final h = HintLadder.hintFor('had', 2, 'EN');
      expect(clips(h.speech), ['h', 'rime_ad', null]); // h.mp3, rime_ad.mp3
    });

    test('digraphs are one sound: th, sh, ch', () {
      expect(say(Phonics.firstSounds('then')), ['thuh']);
      expect(say(Phonics.firstSounds('ship')), ['shh']);
      expect(say(Phonics.firstSounds('chip')), ['chuh']);
      expect(say(Phonics.onsetRime('ship')), ['shh', 'ip', 'ship']);
    });

    test('blends say each sound: str → suh, tuh, ruh', () {
      expect(say(Phonics.firstSounds('strong')), ['suh', 'tuh', 'ruh']);
      expect(say(Phonics.onsetRime('flew')), ['fuh', 'luh', 'oo', 'flew']);
      expect(say(Phonics.firstSounds('school')), ['suh', 'kuh']);
    });

    test('short vowels, vowel teams and magic e at the start', () {
      expect(say(Phonics.firstSounds('apple')), ['ah']);
      expect(say(Phonics.firstSounds('it')), ['ih']);
      expect(say(Phonics.firstSounds('up')), ['uh']);
      expect(say(Phonics.firstSounds('each')), ['ee']);
      expect(say(Phonics.firstSounds('out')), ['ow']);
      expect(say(Phonics.firstSounds('ate')), ['ay']);
      expect(say(Phonics.onsetRime('and')), ['ah', 'and']);
    });

    test('soft c, silent letters and qu', () {
      expect(say(Phonics.firstSounds('city')), ['suh']);
      expect(say(Phonics.firstSounds('cat')), ['kuh']);
      expect(say(Phonics.firstSounds('knot')), ['nuh']);
      expect(say(Phonics.firstSounds('write')), ['ruh']);
      expect(say(Phonics.onsetRime('quick')), ['kwuh', 'ick', 'quick']);
    });

    test('rimes that TTS would say as letter names are respelled', () {
      expect(say(Phonics.onsetRime('he')), ['huh', 'ee', 'he']);
      expect(say(Phonics.onsetRime('go')), ['guh', 'oh', 'go']);
      expect(say(Phonics.onsetRime('my')), ['mmm', 'eye', 'my']);
      expect(say(Phonics.onsetRime('through')), ['thuh', 'ruh', 'oo', 'through']);
    });

    test('irregular sight words use how they sound', () {
      expect(say(Phonics.onsetRime('the')), ['thuh', 'uh', 'the']);
      expect(say(Phonics.onsetRime('was')), ['wuh', 'uz', 'was']);
      expect(say(Phonics.firstSounds('one')), ['wuh']); // not "ah"
      expect(say(Phonics.onsetRime('said')), ['suh', 'ed', 'said']);
      expect(say(Phonics.firstSounds('are')), ['ar']);
    });

    test('longer English words: syllables, then the word', () {
      expect(say(HintLadder.hintFor('basket', 2, 'EN').speech),
          ['bas', 'ket', 'basket']);
      expect(say(HintLadder.hintFor('again', 2, 'EN').speech),
          ['uh', 'gain', 'again']);
      expect(say(HintLadder.hintFor('shiny', 2, 'EN').speech),
          ['shi', 'nee', 'shiny']);
    });

    test('Filipino keeps syllables: ba / ba… ta… bata', () {
      final l1 = HintLadder.hintFor('bata', 1, 'FIL');
      expect(l1.parts, ['ba']);
      expect(say(l1.speech), ['ba']);
      expect(say(HintLadder.hintFor('bangka', 2, 'FIL').speech),
          ['bang', 'ka', 'bangka']);
      expect(say(HintLadder.hintFor('may', 2, 'FIL').speech), ['ma', 'may']);
    });

    test('no letter is ever spoken alone (a letter name), every story word',
        () {
      final stories =
          parseStories(File('assets/data/stories.json').readAsStringSync());
      for (final s in stories) {
        for (final w in s.words) {
          for (final level in [1, 2, 3]) {
            final h = HintLadder.hintFor(w.word, level, s.language);
            expect(h.speech, isNotEmpty, reason: '${w.word} L$level');
            for (final p in h.speech) {
              // "a" and "I" are words, said as words at level 3. Filipino
              // vowel names are their sounds ("a" in "aso").
              final isWord = p.clip == null && p.tts == WordMatcher.normalize(w.word);
              final filVowel = s.language == 'FIL' && 'aeiou'.contains(p.tts);
              if (!isWord && !filVowel) {
                expect(p.tts.length, greaterThan(1),
                    reason: '"${w.word}" level $level says "${p.tts}"');
              }
              if (p.clip != null && !p.clip!.startsWith('rime_')) {
                expect(Phonics.sounds, contains(p.clip), reason: w.word);
              }
            }
          }
        }
      }
    });
  });
}
