import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaloud_buddy/speech/model_store.dart';

/// A tiny stand-in for the Filipino model zip, served by a local server.
void main() {
  late Directory tmp;
  late HttpServer server;
  late List<int> zip;
  late ModelSpec spec;
  final ranges = <String?>[];
  var breakAfter = -1; // the server drops the connection after this many bytes

  List<int> makeZip(String name) {
    final a = Archive();
    for (final f in const ['am/final.mdl', 'conf/model.conf', 'graph/HCLG.fst', 'graph/words.txt', 'README']) {
      final data = List<int>.generate(3000, (i) => (i * 7 + f.length) % 251);
      a.addFile(ArchiveFile.bytes('$name/$f', data));
    }
    return ZipEncoder().encode(a);
  }

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('model_store');
    zip = makeZip('test-model');
    ranges.clear();
    breakAfter = -1;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final range = req.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      var start = 0;
      if (range != null) {
        start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)![1]!);
        req.response.statusCode = HttpStatus.partialContent;
      }
      final body = zip.sublist(start);
      if (breakAfter >= 0) {
        // The connection ends early (like a dropped download).
        req.response.add(body.sublist(0, breakAfter));
        await req.response.close();
        return;
      }
      req.response.add(body);
      await req.response.close();
    });
    spec = ModelSpec(
      name: 'test-model',
      url: 'http://127.0.0.1:${server.port}/test-model.zip',
      sizeBytes: zip.length,
      md5: md5.convert(zip).toString(),
      unpackedMb: 1,
    );
  });

  tearDown(() async {
    await server.close(force: true);
    tmp.deleteSync(recursive: true);
  });

  ModelStore store({int? freeMb, ModelSpec? s}) => ModelStore(
        spec: s ?? spec,
        installDir: () async => Directory('${tmp.path}/models'),
        copyDir: () async => Directory('${tmp.path}/copy')..createSync(recursive: true),
        freeSpaceMb: () async => freeMb,
      );

  test('downloads with progress, checks, unpacks and deletes the zip', () async {
    final steps = await store().download().toList();
    final phases = steps.map((s) => s.phase).toSet();
    expect(phases, containsAll([ModelPhase.downloading, ModelPhase.verifying, ModelPhase.unpacking]));
    final received = [for (final s in steps) if (s.phase == ModelPhase.downloading) s.received];
    expect(received, [...received]..sort()); // only goes up
    expect(steps.last.phase, ModelPhase.ready);
    final path = steps.last.path!;
    expect(File('$path/graph/HCLG.fst').existsSync(), isTrue);
    expect(File('$path/.ready').existsSync(), isTrue);
    expect(File('${tmp.path}/models/test-model.zip.part').existsSync(), isFalse);
    expect(await store().readyPath(), path);
  });

  test('an interrupted download carries on where it stopped', () async {
    breakAfter = 1000;
    final first = await store().download().toList();
    expect(first.last.phase, ModelPhase.failed);
    expect(File('${tmp.path}/models/test-model.zip.part').lengthSync(), 1000);
    breakAfter = -1;
    final second = await store().download().toList();
    expect(second.last.phase, ModelPhase.ready);
    expect(ranges.last, 'bytes=1000-');
  });

  test('a damaged download (wrong MD5) is deleted and reported', () async {
    final bad = ModelSpec(name: spec.name, url: spec.url, sizeBytes: spec.sizeBytes, md5: '0' * 32, unpackedMb: 1);
    final steps = await store(s: bad).download().toList();
    expect(steps.last.phase, ModelPhase.failed);
    expect(steps.last.error, contains('damaged'));
    expect(File('${tmp.path}/models/test-model.zip.part').existsSync(), isFalse);
    expect(await store(s: bad).readyPath(), isNull);
  });

  test('no internet: says so', () async {
    await server.close(force: true);
    final steps = await store().download().toList();
    expect(steps.last.phase, ModelPhase.failed);
    expect(steps.last.error, contains('No internet'));
  });

  test('not enough space: says so before downloading', () async {
    final steps = await store(freeMb: 1).download().toList();
    expect(steps.single.phase, ModelPhase.failed);
    expect(steps.single.error, contains('Not enough space'));
    expect(ranges, isEmpty);
  });

  test('cancel: stops, keeps what was downloaded', () async {
    final token = CancelToken();
    final steps = <ModelStatus>[];
    await for (final s in store().download(cancel: token)) {
      steps.add(s);
      if (s.phase == ModelPhase.downloading) token.cancel();
    }
    expect(steps.last.phase, ModelPhase.missing);
  });

  test('a zip copied onto the phone is checked, unpacked and removed', () async {
    File('${tmp.path}/copy/test-model.zip')
      ..createSync(recursive: true)
      ..writeAsBytesSync(zip);
    final steps = await store().installCopied().toList();
    expect(steps.last.phase, ModelPhase.ready);
    expect(File('${tmp.path}/copy/test-model.zip').existsSync(), isFalse);
    expect(ranges, isEmpty); // no internet used
  });

  test('an unpacked folder copied onto the phone is used where it is', () async {
    final folder = Directory('${tmp.path}/copy/test-model');
    for (final f in spec.requiredFiles) {
      File('${folder.path}/$f').createSync(recursive: true);
    }
    expect(await store().readyPath(), folder.path);
    expect((await store().installCopied().toList()).last.phase, ModelPhase.ready);
  });

  test('nothing copied: says where to put it', () async {
    final steps = await store().installCopied().toList();
    expect(steps.last.phase, ModelPhase.failed);
    expect(steps.last.error, contains('test-model.zip'));
    expect(steps.last.error, contains('copy'));
  });

  test('a half-unpacked model is never used; delete frees everything', () async {
    Directory('${tmp.path}/models/test-model/am').createSync(recursive: true);
    expect(await store().readyPath(), isNull); // no .ready file
    await store().download().drain<void>();
    expect(await store().readyPath(), isNotNull);
    await store().delete();
    expect(await store().readyPath(), isNull);
    expect(Directory('${tmp.path}/models/test-model').existsSync(), isFalse);
  });

  test('the real Filipino model: size and MD5 from the Vosk model list', () {
    expect(filipinoModel.sizeBytes, 329169068);
    expect(filipinoModel.md5, '90b3dd8115dabdb4845972c2eb22797b');
    expect(filipinoModel.url, endsWith('/vosk-model-tl-ph-generic-0.6.zip'));
  });
}
