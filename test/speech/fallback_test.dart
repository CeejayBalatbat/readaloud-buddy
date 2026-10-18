import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/data/database_providers.dart';
import 'package:readaloud_buddy/data/db/app_database.dart';
import 'package:readaloud_buddy/data/repositories/settings_repository.dart';
import 'package:readaloud_buddy/speech/device_info.dart';
import 'package:readaloud_buddy/speech/fake_speech_service.dart';
import 'package:readaloud_buddy/speech/fallback_speech_service.dart';
import 'package:readaloud_buddy/speech/filipino_model.dart';
import 'package:readaloud_buddy/speech/model_store.dart';
import 'package:readaloud_buddy/speech/speech_providers.dart';
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
    late TestRecognizer vosk;
    late FakeSpeechService tap;
    late List<String> failures;
    late FallbackSpeechService s;
    late List<String> heard;

    setUp(() {
      vosk = TestRecognizer('Vosk');
      tap = FakeSpeechService();
      failures = [];
      s = FallbackSpeechService(
          primary: vosk, fallback: () => tap, onFailed: failures.add, note: voskOffNote);
      heard = [];
      s.words.listen((w) => heard.add(w.text));
    });

    test('Vosk fails mid-story: switch to tap-to-read and carry on', () async {
      await s.start(language: 'EN');
      s.expectedWord = 'cat';
      s.vocabulary = ['the', 'cat'];
      vosk.setStatus(MicStatus.unavailable, 'Vosk: KaldiFatalError');
      await Future<void>.delayed(Duration.zero);
      expect(failures, ['Vosk: KaldiFatalError']);
      expect(s.usingFallback, isTrue);
      expect(vosk.stopped, isTrue);
      expect(tap.isListening, isTrue);
      expect(tap.vocabularyNow, ['the', 'cat']);
      expect(s.state.value.notice, voskOffNote);
      // The reading screen finds the tap-to-read service behind it.
      expect(tapToRead(s), same(tap));
      expect(s.hearsSilence, isFalse); // no "can't hear you" while tapping
      tap.hear('cat');
      await Future<void>.delayed(Duration.zero);
      expect(heard, ['cat']);
    });

    test('while Vosk works, the reading screen has no tap-to-read service', () {
      expect(tapToRead(s), isNull);
      expect(tapToRead(tap), same(tap));
    });

    test('no microphone permission is not a recognizer failure', () {
      vosk.setStatus(MicStatus.noPermission);
      expect(failures, isEmpty);
      expect(s.usingFallback, isFalse);
      expect(s.state.value.status, MicStatus.noPermission);
    });

    test('already failed before: starts on tap-to-read with the note', () async {
      final f = FallbackSpeechService.alreadyFailed(fallback: () => tap, note: voskOffNote);
      await f.start(language: 'EN');
      expect(tap.isListening, isTrue);
      expect(f.state.value.notice, voskOffNote);
      expect(tapToRead(f), same(tap));
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
      expect(await c.read(voskHealthProvider('EN').future), isNull);
    });

    test('the app crashed while Vosk was running: Vosk is turned off', () async {
      final t = DateTime(2026, 10, 17, 18);
      await wasRunningAt(t);
      exit.exit = AppExit(reason: 5, timestamp: t.add(const Duration(seconds: 3)));
      expect(await c.read(voskHealthProvider('EN').future), VoskHealth.crashReason);
      expect(await SettingsRepository(db).get(SettingKeys.voskActive), isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskFailed), VoskHealth.crashReason);
    });

    test('the app was just closed while reading: no failure', () async {
      final t = DateTime(2026, 10, 17, 18);
      await wasRunningAt(t);
      exit.exit = AppExit(reason: 10, timestamp: t.add(const Duration(minutes: 1))); // user closed it
      expect(await c.read(voskHealthProvider('EN').future), isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskActive), isNull);
    });

    test('Android can\'t say why (older phone): treated as a crash', () async {
      await wasRunningAt(DateTime(2026, 10, 17, 18));
      expect(await c.read(voskHealthProvider('EN').future), isNotNull);
    });

    test('an old crash from before Vosk ran doesn\'t count', () async {
      final t = DateTime(2026, 10, 17, 18);
      await wasRunningAt(t);
      exit.exit = AppExit(reason: 5, timestamp: t.subtract(const Duration(days: 1)));
      expect(await c.read(voskHealthProvider('EN').future), isNull);
    });

    test('"Try offline again" clears it', () async {
      await c.read(voskHealthProvider('EN').future);
      await c.read(voskHealthProvider('EN').notifier).fail('broken');
      expect(c.read(voskHealthProvider('EN')).value, 'broken');
      await c.read(voskHealthProvider('EN').notifier).retry();
      expect(c.read(voskHealthProvider('EN')).value, isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskFailed), isNull);
    });
  });

  group('VoskHealth per language', () {
    test('Filipino failing leaves English on, and vice versa', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      final c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exitInfoProvider.overrideWithValue(FakeExit(null)),
      ]);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await c.read(voskHealthProvider('FIL').future);
      await c.read(voskHealthProvider('FIL').notifier).fail('too slow');
      expect(await c.read(voskHealthProvider('EN').future), isNull);
      expect(await SettingsRepository(db).get(SettingKeys.voskFilFailed), 'too slow');
    });

    test('killed for low memory or frozen (ANR) while Filipino ran: turned off', () async {
      for (final reason in [3, 6]) {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final db = AppDatabase(NativeDatabase.memory());
        final t = DateTime(2026, 10, 18, 18);
        await SettingsRepository(db).set(SettingKeys.voskFilActive, '${t.millisecondsSinceEpoch}');
        final c = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exitInfoProvider.overrideWithValue(
              FakeExit(AppExit(reason: reason, timestamp: t.add(const Duration(seconds: 5))))),
        ]);
        expect(await c.read(voskHealthProvider('FIL').future), VoskHealth.crashReason,
            reason: 'exit reason $reason');
        expect(await c.read(voskHealthProvider('EN').future), isNull);
        c.dispose();
        await db.close();
      }
    });
  });

  group('which listening a story gets', () {
    late AppDatabase db;
    late ProviderContainer c;
    late Directory dir;

    /// A phone with ([withModel]) or without the Filipino model.
    Future<void> phone({required bool withModel}) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      dir = Directory.systemTemp.createTempSync('fil_model');
      if (withModel) {
        final m = Directory('${dir.path}/models/${filipinoModel.name}');
        for (final f in filipinoModel.requiredFiles) {
          File('${m.path}/$f').createSync(recursive: true);
        }
        File('${m.path}/.ready').writeAsStringSync('ok');
      }
      c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exitInfoProvider.overrideWithValue(FakeExit(null)),
        voskMissingWordsProvider.overrideWith((ref) async => const VoskMissingWords()),
        filipinoModelStoreProvider.overrideWithValue(ModelStore(
          spec: filipinoModel,
          installDir: () async => Directory('${dir.path}/models'),
        )),
      ]);
      addTearDown(() async {
        c.dispose();
        await db.close();
        dir.deleteSync(recursive: true);
      });
      await c.read(speechModeProvider.future);
      await c.read(voskHealthProvider('EN').future);
      await c.read(voskHealthProvider('FIL').future);
      await c.read(filipinoModelProvider.notifier).refresh();
    }

    test('English: Vosk; Vosk off: tap with a note; developer mode: tap', () async {
      await phone(withModel: false);
      final en = c.read(speechServiceProvider('EN'));
      expect(en, isA<FallbackSpeechService>());
      expect(tapToRead(en), isNull); // the microphone

      await c.read(voskHealthProvider('EN').notifier).fail('broken');
      c.invalidate(speechServiceProvider);
      final off = c.read(speechServiceProvider('EN'));
      expect(tapToRead(off), isNotNull);
      expect(off.state.value.notice, voskOffNote);

      await c.read(voskHealthProvider('EN').notifier).retry();
      await c.read(speechModeProvider.notifier).set(SpeechMode.tap);
      expect(c.read(speechServiceProvider('EN')), isA<FakeSpeechService>());
    });

    test('Filipino without the model: tap to read', () async {
      await phone(withModel: false);
      expect(c.read(filipinoModelProvider).phase, ModelPhase.missing);
      expect(c.read(speechServiceProvider('FIL')), isA<FakeSpeechService>());
    });

    test('Filipino with the model: Vosk (free text); too heavy: tap with a note', () async {
      await phone(withModel: true);
      expect(c.read(filipinoModelProvider).isReady, isTrue);
      final fil = c.read(speechServiceProvider('FIL'));
      expect(fil, isA<FallbackSpeechService>());
      expect(tapToRead(fil), isNull);
      expect(fil.state.value.engine, 'Vosk offline (Filipino, free text)');

      await c.read(voskHealthProvider('FIL').notifier).fail('not enough free memory');
      c.invalidate(speechServiceProvider);
      final off = c.read(speechServiceProvider('FIL'));
      expect(tapToRead(off), isNotNull);
      expect(off.state.value.notice, filipinoOffNote);
      // English is not affected.
      expect(tapToRead(c.read(speechServiceProvider('EN'))), isNull);
    });

    test('free memory check: refuses below the limit', () async {
      await expectLater(checkFreeMemory(_Memory(800), 1200), throwsStateError);
      await checkFreeMemory(_Memory(3000), 1200); // fine
      await checkFreeMemory(_Memory(null), 1200); // unknown: try
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

class _Memory implements DeviceInfo {
  _Memory(this.freeMb);
  final int? freeMb;
  @override
  Future<MemoryInfo?> memory() async =>
      freeMb == null ? null : MemoryInfo(totalMb: 8000, freeMb: freeMb!, appMb: 300);
  @override
  Future<int?> freeSpaceMb() async => null;
}
