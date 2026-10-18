import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database_providers.dart';
import '../data/repositories/settings_repository.dart';
import 'device_info.dart';
import 'model_store.dart';

/// Where the Filipino model lives on this phone: the app's private storage,
/// plus the app's external folder for copying it on from a PC.
final filipinoModelStoreProvider = Provider<ModelStore>((ref) {
  final device = ref.watch(deviceInfoProvider);
  return ModelStore(
    spec: filipinoModel,
    installDir: () async => Directory('${(await getApplicationSupportDirectory()).path}/models'),
    copyDir: () async => getExternalStorageDirectory(),
    freeSpaceMb: device.freeSpaceMb,
  );
});

/// The Filipino model's status, and the grown-up's actions on it.
class FilipinoModel extends Notifier<ModelStatus> {
  CancelToken? _cancel;
  StreamSubscription<ModelStatus>? _sub;

  @override
  ModelStatus build() {
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(refresh);
    return const ModelStatus(ModelPhase.checking);
  }

  ModelStore get _store => ref.read(filipinoModelStoreProvider);

  /// Looks on the phone again (e.g. at app start).
  Future<void> refresh() async {
    if (state.isBusy) return;
    try {
      state = await _store.check();
    } catch (e) {
      state = ModelStatus(ModelPhase.failed, error: '$e');
    }
  }

  /// Downloads and installs it. Completes when ready, failed or cancelled.
  Future<ModelStatus> download() => _run(_store.download(cancel: _cancel = CancelToken()));

  /// Uses a zip or folder copied onto the phone.
  Future<ModelStatus> installCopied() => _run(_store.installCopied());

  void cancel() => _cancel?.cancel();

  Future<void> delete() async {
    cancel();
    await _sub?.cancel();
    await _store.delete();
    state = const ModelStatus(ModelPhase.missing);
  }

  Future<ModelStatus> _run(Stream<ModelStatus> steps) {
    final done = Completer<ModelStatus>();
    _sub?.cancel();
    _sub = steps.listen(
      (s) => state = s,
      onError: (Object e) => state = ModelStatus(ModelPhase.failed, error: '$e'),
      onDone: () => done.complete(state),
    );
    return done.future;
  }
}

final filipinoModelProvider = NotifierProvider<FilipinoModel, ModelStatus>(FilipinoModel.new);

/// The grown-up chose "Not now" on the setup screen: don't ask again
/// before every Filipino story (Settings can still download it).
class FilipinoSetupDeclined extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      await ref.watch(settingsRepositoryProvider).get(SettingKeys.filipinoModelDeclined) != null;

  Future<void> set(bool declined) async {
    final s = ref.read(settingsRepositoryProvider);
    declined ? await s.set(SettingKeys.filipinoModelDeclined, '1') : await s.remove(SettingKeys.filipinoModelDeclined);
    state = AsyncData(declined);
  }
}

final filipinoSetupDeclinedProvider =
    AsyncNotifierProvider<FilipinoSetupDeclined, bool>(FilipinoSetupDeclined.new);
