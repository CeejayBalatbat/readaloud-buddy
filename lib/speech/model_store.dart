import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

/// A Vosk model that is downloaded (or copied) instead of bundled.
class ModelSpec {
  const ModelSpec({
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.md5,
    required this.unpackedMb,
    this.requiredFiles = const ['am/final.mdl', 'conf/model.conf', 'graph/HCLG.fst', 'graph/words.txt'],
  });

  /// Also the zip's file name (without .zip) and the folder inside it.
  final String name;
  final String url;
  final int sizeBytes;
  final String md5;
  final int unpackedMb;

  /// Files a usable (unpacked) model must have.
  final List<String> requiredFiles;

  int get sizeMb => (sizeBytes / (1024 * 1024)).round();

  /// Space needed to install it: the zip and the unpacked model at once.
  int get installSpaceMb => sizeMb + unpackedMb + 50;
}

/// The Filipino model (AGENT_SPEC "Speech recognition"). © 2020 Federico
/// Ang, CC BY-NC-SA 4.0: non-commercial use only. Size and MD5 are from
/// https://alphacephei.com/vosk/models/model-list.json.
const filipinoModel = ModelSpec(
  name: 'vosk-model-tl-ph-generic-0.6',
  url: 'https://alphacephei.com/vosk/models/vosk-model-tl-ph-generic-0.6.zip',
  sizeBytes: 329169068,
  md5: '90b3dd8115dabdb4845972c2eb22797b',
  unpackedMb: 775,
);

enum ModelPhase { checking, missing, downloading, verifying, unpacking, ready, failed }

/// Where a model stands, for the setup screen and Settings.
class ModelStatus {
  const ModelStatus(this.phase, {this.received = 0, this.total = 0, this.path, this.error});

  final ModelPhase phase;

  /// Bytes downloaded so far, of [total] (while downloading).
  final int received;
  final int total;

  /// The unpacked model folder, when [phase] is ready.
  final String? path;

  /// What went wrong, in words for a grown-up (when [phase] is failed).
  final String? error;

  double? get progress => total > 0 ? received / total : null;
  bool get isReady => phase == ModelPhase.ready && path != null;
  bool get isBusy =>
      phase == ModelPhase.downloading || phase == ModelPhase.verifying || phase == ModelPhase.unpacking;

  @override
  String toString() => 'ModelStatus(${phase.name}, $received/$total, $path, $error)';
}

/// Stops a download.
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Downloads, checks, unpacks and finds one model on the phone.
///
/// - [installDir]: the app's private storage; the model ends up in
///   `<installDir>/<name>/` with a `.ready` file once fully unpacked.
/// - [copyDir]: a folder a grown-up can reach from a PC over USB (the app's
///   external files folder); a copied `<name>.zip` or `<name>/` folder there
///   is found by [installCopied].
class ModelStore {
  ModelStore({
    required this.spec,
    required this.installDir,
    this.copyDir,
    HttpClient Function()? http,
    this.freeSpaceMb,
    this.stallTimeout = const Duration(seconds: 30),
  }) : _http = http ?? HttpClient.new;

  final ModelSpec spec;
  final Future<Directory> Function() installDir;
  final Future<Directory?> Function()? copyDir;
  final HttpClient Function() _http;

  /// Free space in [installDir], or null when unknown.
  final Future<int?> Function()? freeSpaceMb;

  /// No data for this long counts as a dropped connection.
  final Duration stallTimeout;

  static const _ready = '.ready';

  Future<Directory> _modelDir() async => Directory('${(await installDir()).path}/${spec.name}');
  Future<File> _partFile() async => File('${(await installDir()).path}/${spec.name}.zip.part');

  bool _complete(Directory d) =>
      spec.requiredFiles.every((f) => File('${d.path}/$f').existsSync());

  /// The usable model folder: installed by the app, or an unpacked folder a
  /// grown-up copied. Null when there is none.
  Future<String?> readyPath() async {
    final dir = await _modelDir();
    if (File('${dir.path}/$_ready').existsSync() && _complete(dir)) return dir.path;
    final copy = await copyDir?.call();
    if (copy != null) {
      final copied = Directory('${copy.path}/${spec.name}');
      if (copied.existsSync() && _complete(copied)) return copied.path;
    }
    return null;
  }

  /// Where a grown-up can copy the zip (shown on screen), if anywhere.
  Future<String?> copyFolder() async => (await copyDir?.call())?.path;

  Future<ModelStatus> check() async {
    final path = await readyPath();
    return path == null ? const ModelStatus(ModelPhase.missing) : ModelStatus(ModelPhase.ready, path: path);
  }

  /// Downloads the zip (resuming a partial download), checks its size and
  /// MD5, unpacks it and deletes the zip. The last status is ready or
  /// failed (or missing when cancelled).
  Stream<ModelStatus> download({CancelToken? cancel}) async* {
    final token = cancel ?? CancelToken();
    final root = await installDir();
    await root.create(recursive: true);
    final part = await _partFile();
    var have = part.existsSync() ? part.lengthSync() : 0;
    if (have > spec.sizeBytes) {
      part.deleteSync();
      have = 0;
    }

    final free = await freeSpaceMb?.call();
    final needMb = spec.installSpaceMb - (have ~/ (1024 * 1024));
    if (free != null && free < needMb) {
      yield ModelStatus(ModelPhase.failed,
          error: 'Not enough space: Filipino listening needs about '
              '${(needMb / 1024).toStringAsFixed(1)} GB free (${(free / 1024).toStringAsFixed(1)} GB free now).');
      return;
    }

    if (have < spec.sizeBytes) {
      final client = _http();
      IOSink? sink;
      try {
        final request = await client.getUrl(Uri.parse(spec.url));
        if (have > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
        final response = await request.close();
        if (response.statusCode == HttpStatus.ok) {
          have = 0; // the server sent the whole file: start over
        } else if (response.statusCode != HttpStatus.partialContent) {
          yield ModelStatus(ModelPhase.failed,
              error: "The download server didn't answer (code ${response.statusCode}). Try again later.");
          return;
        }
        final out = part.openWrite(mode: have == 0 ? FileMode.write : FileMode.append);
        sink = out;
        var lastReport = have;
        yield ModelStatus(ModelPhase.downloading, received: have, total: spec.sizeBytes);
        await for (final chunk in response.timeout(stallTimeout)) {
          if (token.isCancelled) {
            await out.close();
            sink = null;
            yield const ModelStatus(ModelPhase.missing); // the part file stays, to resume
            return;
          }
          out.add(chunk);
          have += chunk.length;
          if (have - lastReport >= 512 * 1024 || have >= spec.sizeBytes) {
            lastReport = have;
            yield ModelStatus(ModelPhase.downloading, received: have, total: spec.sizeBytes);
          }
        }
        await out.close();
        sink = null;
        if (have < spec.sizeBytes) {
          yield const ModelStatus(ModelPhase.failed,
              error: 'The download stopped before the end. Try again (it carries on where it stopped).');
          return;
        }
      } on TimeoutException {
        yield const ModelStatus(ModelPhase.failed,
            error: 'The connection stopped. Try again (the download carries on where it stopped).');
        return;
      } on SocketException {
        yield const ModelStatus(ModelPhase.failed,
            error: "No internet. Connect to Wi-Fi and try again (the download carries on where it stopped).");
        return;
      } on HttpException catch (e) {
        yield ModelStatus(ModelPhase.failed, error: 'The download stopped (${e.message}). Try again.');
        return;
      } on IOException catch (e) {
        yield ModelStatus(ModelPhase.failed, error: 'The download stopped ($e). Try again.');
        return;
      } finally {
        await sink?.close();
        client.close(force: true);
      }
    }
    // The unzip library wants a name ending in .zip.
    final zip = File('${root.path}/${spec.name}.zip');
    if (zip.existsSync()) zip.deleteSync();
    yield* _install(part.renameSync(zip.path), deleteZip: true);
  }

  /// Uses a model a grown-up copied into [copyDir]: an unpacked folder is
  /// used where it is; a zip is checked (MD5), unpacked and deleted.
  Stream<ModelStatus> installCopied() async* {
    final path = await readyPath();
    if (path != null) {
      yield ModelStatus(ModelPhase.ready, path: path);
      return;
    }
    final copy = await copyDir?.call();
    final zip = copy == null ? null : File('${copy.path}/${spec.name}.zip');
    if (zip == null || !zip.existsSync()) {
      yield ModelStatus(ModelPhase.failed,
          error: 'No copied file found. Put ${spec.name}.zip in '
              '${copy?.path ?? "the app's folder"} and try again.');
      return;
    }
    final free = await freeSpaceMb?.call();
    if (free != null && free < spec.unpackedMb + 50) {
      yield ModelStatus(ModelPhase.failed,
          error: 'Not enough space to unpack it: needs about ${spec.unpackedMb} MB free.');
      return;
    }
    yield* _install(zip, deleteZip: true);
  }

  /// Checks [zip] (size and MD5), unpacks it into a temporary folder and
  /// then moves it into place, so a half-unpacked model is never used.
  Stream<ModelStatus> _install(File zip, {required bool deleteZip}) async* {
    yield const ModelStatus(ModelPhase.verifying);
    final zipPath = zip.path;
    if (zip.lengthSync() != spec.sizeBytes) {
      if (deleteZip) zip.deleteSync();
      yield const ModelStatus(ModelPhase.failed,
          error: 'The file is the wrong size (damaged or a different model). Try again.');
      return;
    }
    final digest = await Isolate.run(() async => (await md5.bind(File(zipPath).openRead()).first).toString());
    if (digest != spec.md5) {
      if (deleteZip) zip.deleteSync();
      yield const ModelStatus(ModelPhase.failed,
          error: 'The file is damaged (its check doesn\'t match). Try again.');
      return;
    }

    yield const ModelStatus(ModelPhase.unpacking);
    final root = await installDir();
    final tmp = Directory('${root.path}/${spec.name}.unpacking');
    final dest = await _modelDir();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      final tmpPath = tmp.path;
      await Isolate.run(() => extractFileToDisk(zipPath, tmpPath));
      final unpacked = Directory('${tmp.path}/${spec.name}');
      if (!_complete(unpacked)) {
        tmp.deleteSync(recursive: true);
        yield const ModelStatus(ModelPhase.failed, error: "The file doesn't contain the expected model.");
        return;
      }
      if (dest.existsSync()) dest.deleteSync(recursive: true);
      unpacked.renameSync(dest.path);
      tmp.deleteSync(recursive: true);
      File('${dest.path}/$_ready').writeAsStringSync(spec.md5);
    } on FileSystemException catch (e) {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      yield ModelStatus(ModelPhase.failed, error: "Couldn't unpack the model (${e.message}). Is the phone full?");
      return;
    }
    if (deleteZip && File(zipPath).existsSync()) File(zipPath).deleteSync();
    yield ModelStatus(ModelPhase.ready, path: dest.path);
  }

  /// Removes the installed model, a partial download and a copied zip or
  /// folder, to free the space.
  Future<void> delete() async {
    final dir = await _modelDir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final part = await _partFile();
    if (part.existsSync()) part.deleteSync();
    final copy = await copyDir?.call();
    if (copy != null) {
      final zip = File('${copy.path}/${spec.name}.zip');
      if (zip.existsSync()) zip.deleteSync();
      final folder = Directory('${copy.path}/${spec.name}');
      if (folder.existsSync()) folder.deleteSync(recursive: true);
    }
  }
}
