// Runs the app's real Filipino-model code on a phone: install from a copied
// zip, a real download from the Vosk server, loading with the app's engine,
// and handing the microphone between the English and Filipino recognizers.
//
// adb shell pm grant com.readaloudbuddy.readaloud_buddy android.permission.RECORD_AUDIO
// adb push vosk-model-tl-ph-generic-0.6.zip /sdcard/Android/data/com.readaloudbuddy.readaloud_buddy/files/
// flutter test integration_test/filipino_on_phone_test.dart -d <phone> --no-uninstall
// (--no-uninstall keeps the app, its data and the model on the phone.)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readaloud_buddy/agent/agent_config.dart';
import 'package:readaloud_buddy/speech/device_info.dart';
import 'package:readaloud_buddy/speech/model_store.dart';
import 'package:readaloud_buddy/speech/speech_providers.dart';
import 'package:readaloud_buddy/speech/vosk_speech_service.dart';

// ignore: avoid_print
void report(String what, Object? value) => print('PHONE $what: ${jsonEncode(value)}');

/// Runs [steps] and reports how long each phase took.
Future<ModelStatus> timed(String name, Stream<ModelStatus> steps) async {
  final sw = Stopwatch()..start();
  ModelPhase? phase;
  var since = 0;
  var lastTenth = -1;
  late ModelStatus last;
  await for (final s in steps) {
    last = s;
    if (s.phase != phase) {
      if (phase != null) report('$name ${phase.name} seconds', (sw.elapsedMilliseconds - since) / 1000);
      phase = s.phase;
      since = sw.elapsedMilliseconds;
    }
    final tenth = ((s.progress ?? 0) * 10).floor();
    if (s.phase == ModelPhase.downloading && tenth != lastTenth) {
      lastTenth = tenth;
      report('$name progress', '${tenth * 10}% at ${sw.elapsedMilliseconds ~/ 1000} s');
    }
  }
  report('$name result', {'phase': last.phase.name, 'error': last.error, 'totalSeconds': sw.elapsedMilliseconds / 1000});
  return last;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Filipino model: install, download, load, microphone', timeout: const Timeout(Duration(minutes: 30)),
      (tester) async {
    const device = PlatformDeviceInfo();
    final support = await getApplicationSupportDirectory();
    final ext = (await getExternalStorageDirectory())!;
    final store = ModelStore(
      spec: filipinoModel,
      installDir: () async => Directory('${support.path}/models'),
      copyDir: () async => ext,
      freeSpaceMb: device.freeSpaceMb,
    );
    report('free space MB', await device.freeSpaceMb());
    report('copy folder', await store.copyFolder());

    // 1. A zip copied onto the phone (pushed with adb).
    final installed = Directory('${support.path}/models/${filipinoModel.name}');
    if (installed.existsSync()) installed.deleteSync(recursive: true);
    if (File('${ext.path}/${filipinoModel.name}.zip').existsSync()) {
      final copied = await timed('copied zip', store.installCopied());
      expect(copied.phase, ModelPhase.ready);
    } else {
      report('copied zip', 'skipped (no zip pushed)');
    }

    // 2. A real download from alphacephei.com (internet needed).
    if (installed.existsSync()) installed.deleteSync(recursive: true);
    final downloaded = await timed('download', store.download());
    expect(downloaded.phase, ModelPhase.ready, reason: downloaded.error);
    final path = downloaded.path!;

    // 3. Load with the app's engine, after the app's memory check.
    report('memory before load', '${await device.memory()}');
    await checkFreeMemory(device, const AgentConfig().filMinFreeMemoryMb);
    final fil = VoskFlutterEngine.filipino(path);
    final sw = Stopwatch()..start();
    await fil.load(const []);
    report('filipino load seconds', sw.elapsedMilliseconds / 1000);
    report('memory after filipino load', '${await device.memory()}');

    // 4. The microphone: English, then Filipino, then English again.
    final en = VoskFlutterEngine.english;
    sw.reset();
    await en.load(const ['sam', '[unk]']);
    report('english load seconds', sw.elapsedMilliseconds / 1000);
    for (final (name, engine) in [('english', en), ('filipino', fil), ('english again', en)]) {
      sw.reset();
      await engine.start();
      report('$name mic start ms', sw.elapsedMilliseconds);
      await Future<void>.delayed(const Duration(seconds: 2));
      await engine.stop();
    }
    report('memory at the end', '${await device.memory()}');
  });
}
