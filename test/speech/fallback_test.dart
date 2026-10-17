import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/data/database_providers.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/repositories/settings_repository.dart';
import 'package:readaloud_buddy/speech/fallback_speech_service.dart';
import 'package:readaloud_buddy/speech/speech_service.dart';
import 'package:readaloud_buddy/speech/vosk_health.dart';
import 'package:readaloud_buddy/speech/vosk_speech_service.dart';

import 'vosk_speech_service_test.dart' show FakeVosk, Mic;

/// A recognizer the test controls.
class TestRecognizer implements SpeechService {
  TestRecognizer(this.name);
  final String name;
  final starts = <String>[];
  String? expected;
  List<String> vocab = const [];
  bool stopped = false;
  final words_ = StreamController<HeardWord>.broadcast(sync: true);
  final _state = ValueNotifier(const SpeechState());

  void setStatus(MicStatus s, [String? error]) =>
      _state.value = SpeechState(status: s, lastError: error, engine: name);

  @override
  Stream<HeardWord> get words => words_.stream;
  @override
  Stream<void> get voice => const Stream.empty();
  @override
  bool get hearsSilence => true;
  @override
  ValueListenable<SpeechState> get state => _state;
  @override
  bool get isListening => _state.value.status == MicStatus.listening;
  @override
  set expectedWord(String? word) => expected = word;
  @override
  set vocabulary(List<String> words) => vocab = words;
  @override
  void mute(bool muted) {}
  @override
  Future<void> start({required String language}) async {
    starts.add(language);
    setStatus(MicStatus.listening);
  }

  @override
  Future<void> stop() async => stopped = true;
  @override
  void dispose() {}
}

class FakeExit implements ExitInfo {
  FakeExit(this.exit);
  AppExit? exit;
  @override
  Future<AppExit?> lastExit() async => exit;
}

void main() {
  group('FallbackSpeechService', () {
    late TestRecognizer vosk, phone;
    late List<String> failures;
    late FallbackSpeechService s;
    late List<String> heard;

    setUp(() {
      vosk = TestRecognizer('Vosk');
      phone = TestRecognizer('Android');
      failures = [];
      s = FallbackSpeechService(primary: vosk, fallback: () => phone, onFailed: failures.add);
      heard = [];
      s.words.listen((w) => heard.add(w.text));
    });

    test('Vosk fails mid-story: switch to the phone recognizer and carry on', () async {
      await s.start(language: 'EN');
      s.expectedWord = 'cat';
      s.vocabulary = ['the', 'cat'];
      vosk.setStatus(MicStatus.unavailable, 'Vosk: KaldiFatalError');
      await Future<void>.delayed(Duration.zero);
      expect(failures, ['Vosk: KaldiFatalError']);
      expect(s.usingFallback, isTrue);
      expect(vosk.stopped, isTrue);
      expect(phone.starts, ['EN']);
      expect(phone.expected, 'cat');
      expect(phone.vocab, ['the', 'cat']);
      expect(s.state.value.notice, FallbackSpeechService.defaultNote);
      phone.words_.add(const HeardWord('cat'));
      expect(heard, ['cat']);
    });

    test('no microphone permission is not a recognizer failure', () {
      vosk.setStatus(MicStatus.noPermission);
      expect(failures, isEmpty);
      expect(s.usingFallback, isFalse);
      expect(s.state.value.status, MicStatus.noPermission);
    });

    test('already failed before: starts on the phone recognizer with the note', () async {
      final f = FallbackSpeechService.alreadyFailed(fallback: () => phone);
      await f.start(language: 'EN');
      expect(phone.starts, ['EN']);
      expect(f.state.value.notice, isNotNull);
    });
  });

  group('VoskHealth (remembering a failure)', () {
    late AppDatabase db;
    late FakeExit exit;
    late ProviderContainer c;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      exit = FakeExit(null);
      c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exitInfoProvider.overrideWithValue(exit),
      ]);
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    Future<void> wasRunningAt(DateTime t) => SettingsRepository(db)
        .set(SettingKeys.voskActive, '${t.millisecondsSinceEpoch}');

    test('fine by default', () async {
      expect(await c.read(voskHealthProvider.future), isNull);
    });

    test('the app crashed while Vosk was running: Vosk is turned off', () async {
      final t = DateTime(2026, 10, 17, 18);
      await wasRunningAt(t);
      exit.exit = AppExit(reason: 5, timestamp: t.add(const Duration(seconds: 3)));
      expect(await c.read(voskHealthProvider.future), VoskHealth.crashReason);
      expect(await SettingsRepository(db).get(SettingKeys.voskActive), isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskFailed), VoskHealth.crashReason);
    });

    test('the app was just closed while reading: no failure', () async {
      final t = DateTime(2026, 10, 17, 18);
      await wasRunningAt(t);
      exit.exit = AppExit(reason: 10, timestamp: t.add(const Duration(minutes: 1))); // user closed it
      expect(await c.read(voskHealthProvider.future), isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskActive), isNull);
    });

    test('Android can\'t say why (older phone): treated as a crash', () async {
      await wasRunningAt(DateTime(2026, 10, 17, 18));
      expect(await c.read(voskHealthProvider.future), isNotNull);
    });

    test('an old crash from before Vosk ran doesn\'t count', () async {
      final t = DateTime(2026, 10, 17, 18);
      await wasRunningAt(t);
      exit.exit = AppExit(reason: 5, timestamp: t.subtract(const Duration(days: 1)));
      expect(await c.read(voskHealthProvider.future), isNull);
    });

    test('"Try offline again" clears it', () async {
      await c.read(voskHealthProvider.future);
      await c.read(voskHealthProvider.notifier).fail('broken');
      expect(c.read(voskHealthProvider).value, 'broken');
      await c.read(voskHealthProvider.notifier).retry();
      expect(c.read(voskHealthProvider).value, isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskFailed), isNull);
    });
  });

  group('VoskSpeechService errors', () {
    test('marks itself running/stopped and reports any Vosk error as unavailable',
        () async {
      final engine = _GrammarFails();
      final running = <bool>[];
      final s = VoskSpeechService(
        engine: engine,
        permissions: Mic(),
        grammarSwapDelay: Duration.zero,
        onRunning: (on) async => running.add(on),
        onNextFrame: (_) {},
      );
      await s.start(language: 'EN');
      expect(running, [true]);
      engine.failNext = true;
      s.vocabulary = ['new', 'page'];
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(s.state.value.status, MicStatus.unavailable);
      expect(s.state.value.lastError, contains('refused'));
      expect(running, [true, false]);
    });
  });
}

class _GrammarFails extends FakeVosk {
  bool failNext = false;
  @override
  Future<void> setGrammar(List<String> grammar) async {
    if (failNext) throw StateError('grammar refused');
    return super.setGrammar(grammar);
  }
}
