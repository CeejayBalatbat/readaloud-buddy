// Measures the Filipino Vosk model on a real phone: unpack time, load time,
// memory, decoding speed and word accuracy on Filipino speech made by the
// phone's own text-to-speech (Google TTS, fil-PH).
//
// 1. Copy the model zip to the phone (once):
//      adb push vosk-model-tl-ph-generic-0.6.zip \
//        /sdcard/Android/data/com.readaloudbuddy.readaloud_buddy/files/
// 2. flutter test integration_test/filipino_model_benchmark_test.dart -d <phone>
// Results are printed as lines starting with "BENCH".

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readaloud_buddy/agent/word_matcher.dart';
import 'package:readaloud_buddy/data/story.dart';
import 'package:vosk_flutter/vosk_flutter.dart' as vosk;

const modelName = 'vosk-model-tl-ph-generic-0.6';
const device = MethodChannel('readaloud/device');

// ignore: avoid_print
void report(String what, Object? value) => print('BENCH $what: ${jsonEncode(value)}');

Future<Map<String, dynamic>> memory() async =>
    Map<String, dynamic>.from(await device.invokeMethod<Map>('memory') ?? {});

/// 16-bit PCM WAV: (sample rate, channels, samples bytes).
(int, int, Uint8List) readWav(Uint8List b) {
  final d = ByteData.sublistView(b);
  var i = 12, rate = 0, channels = 1;
  while (i + 8 <= b.length) {
    final id = String.fromCharCodes(b.sublist(i, i + 4));
    final size = d.getUint32(i + 4, Endian.little);
    if (id == 'fmt ') {
      channels = d.getUint16(i + 10, Endian.little);
      rate = d.getUint32(i + 12, Endian.little);
    } else if (id == 'data') {
      return (rate, channels, b.sublist(i + 8, (i + 8 + size).clamp(0, b.length)));
    }
    i += 8 + size + (size.isOdd ? 1 : 0);
  }
  throw const FormatException('no data chunk');
}

/// Words of [expected] found, in order, in [heard] (longest common subsequence).
int inOrder(List<String> expected, List<String> heard) {
  final dp = List.generate(expected.length + 1, (_) => List.filled(heard.length + 1, 0));
  for (var i = 1; i <= expected.length; i++) {
    for (var j = 1; j <= heard.length; j++) {
      dp[i][j] = expected[i - 1] == heard[j - 1]
          ? dp[i - 1][j - 1] + 1
          : (dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
    }
  }
  return dp[expected.length][heard.length];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Filipino Vosk model on this phone', timeout: const Timeout(Duration(minutes: 20)),
      (tester) async {
    report('phone memory before', await memory());

    // --- Unpack the zip copied to the app's folder (like a manual copy).
    final ext = (await getExternalStorageDirectory())!;
    final zip = File('${ext.path}/$modelName.zip');
    final models = Directory('${(await getApplicationSupportDirectory()).path}/models');
    final modelDir = Directory('${models.path}/$modelName');
    if (!File('${modelDir.path}/.ready').existsSync()) {
      expect(zip.existsSync(), isTrue, reason: 'adb push the zip to ${ext.path} first');
      final sw = Stopwatch()..start();
      await extractFileToDisk(zip.path, models.path);
      File('${modelDir.path}/.ready').writeAsStringSync('ok');
      report('unzip seconds', sw.elapsedMilliseconds / 1000);
    }

    // --- Load the model and a free-text recognizer (no grammar).
    final plugin = vosk.VoskFlutterPlugin.instance();
    final sw = Stopwatch()..start();
    final model = await plugin.createModel(modelDir.path);
    report('model load seconds', sw.elapsedMilliseconds / 1000);
    report('phone memory after load', await memory());

    // --- Filipino speech from the phone's TTS, one file per story.
    final tts = FlutterTts();
    await tts.setEngine('com.google.android.tts');
    await tts.awaitSynthCompletion(true);
    report('fil-PH voice available', await tts.isLanguageAvailable('fil-PH'));
    await tts.setLanguage('fil-PH');
    await tts.setSpeechRate(0.42); // a little slower than normal, like a child reading
    final stories = parseStories(await rootBundle.loadString('assets/data/stories.json'))
        .where((s) => s.language == 'FIL')
        .toList();

    var totalAudio = 0.0, totalDecode = 0.0, found = 0, total = 0;
    for (final s in stories) {
      final wavPath = '${ext.path}/bench_${s.id}.wav';
      await tts.synthesizeToFile(s.text, wavPath, true);
      final (rate, channels, pcm) = readWav(File(wavPath).readAsBytesSync());
      expect(channels, 1);
      final recognizer = await plugin.createRecognizer(model: model, sampleRate: rate);
      final chunk = rate * 2 ~/ 4; // 0.25 s of 16-bit audio
      final texts = <String>[];
      final t = Stopwatch()..start();
      for (var i = 0; i < pcm.length; i += chunk) {
        final end = (i + chunk).clamp(0, pcm.length);
        if (await recognizer.acceptWaveformBytes(Uint8List.sublistView(pcm, i, end))) {
          texts.add((jsonDecode(await recognizer.getResult()) as Map)['text'] as String);
        }
      }
      texts.add((jsonDecode(await recognizer.getFinalResult()) as Map)['text'] as String);
      final decode = t.elapsedMilliseconds / 1000;
      await recognizer.dispose();

      final audio = pcm.length / 2 / rate;
      final heard = texts.join(' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final expected = [
        for (final w in s.words) ...WordMatcher.normalize(w.word).split('-'),
      ].where((w) => w.isNotEmpty).toList();
      final ok = inOrder(expected, heard);
      totalAudio += audio;
      totalDecode += decode;
      found += ok;
      total += expected.length;
      report('story ${s.id}', {
        'audioSeconds': audio.toStringAsFixed(1),
        'decodeSeconds': decode.toStringAsFixed(1),
        'realTimeFactor': (decode / audio).toStringAsFixed(2),
        'wordsFound': '$ok/${expected.length}',
        'heard': heard.join(' '),
      });
    }
    report('summary', {
      'realTimeFactor': (totalDecode / totalAudio).toStringAsFixed(2),
      'wordsFoundPercent': (100 * found / total).toStringAsFixed(1),
      'audioSeconds': totalAudio.round(),
    });
    report('phone memory after decoding', await memory());
  });
}
