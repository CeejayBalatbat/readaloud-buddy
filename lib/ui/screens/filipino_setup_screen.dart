import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../speech/filipino_model.dart';
import '../../speech/model_store.dart';
import '../../speech/speech_providers.dart';
import '../../speech/vosk_health.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/common.dart';

/// Before a Filipino story (or a Filipino reader's reading check): if the
/// Filipino model isn't on the phone yet, a grown-up decides whether to
/// download it (screen 5c). Returns at once when it's not needed: tap
/// mode, already set up, Filipino Vosk turned off, or "Not now" before.
Future<void> ensureFilipinoListening(BuildContext context) async {
  final c = ProviderScope.containerOf(context);
  final navigator = Navigator.of(context);
  if ((c.read(speechModeProvider).value ?? SpeechMode.vosk) == SpeechMode.tap) return;
  if (await c.read(voskHealthProvider('FIL').future) != null) return;
  final model = c.read(filipinoModelProvider.notifier);
  if (c.read(filipinoModelProvider).phase == ModelPhase.checking) await model.refresh();
  if (c.read(filipinoModelProvider).isReady) return;
  if (await c.read(filipinoSetupDeclinedProvider.future)) return;
  await navigator.push(MaterialPageRoute<void>(builder: (_) => const FilipinoSetupScreen()));
}

/// Screen 5c: set up Filipino listening (download once, or a copied file).
class FilipinoSetupScreen extends ConsumerStatefulWidget {
  const FilipinoSetupScreen({super.key});

  @override
  ConsumerState<FilipinoSetupScreen> createState() => _FilipinoSetupScreenState();
}

class _FilipinoSetupScreenState extends ConsumerState<FilipinoSetupScreen> {
  String? _copyFolder;

  static const _small = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink2);

  @override
  void initState() {
    super.initState();
    ref.read(filipinoModelStoreProvider).copyFolder().then((f) {
      if (mounted) setState(() => _copyFolder = f);
    });
  }

  FilipinoModel get _model => ref.read(filipinoModelProvider.notifier);

  Future<void> _notNow() async {
    _model.cancel();
    await ref.read(filipinoSetupDeclinedProvider.notifier).set(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(filipinoModelProvider);
    const spec = filipinoModel;
    int mb(int bytes) => (bytes / (1024 * 1024)).round();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            children: [
              ScreenHeader(title: 'For grown-ups', onClose: () => Navigator.of(context).pop()),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Buddy(size: 78),
                          SizedBox(width: 12),
                          Expanded(child: SpeechBubble('I can listen in Filipino too!')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Filipino listening',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(
                              'To follow Filipino reading, Buddy needs a Filipino listening file '
                              '(${spec.sizeMb} MB). It downloads once: internet is needed now '
                              '(Wi-Fi is best), then it works offline. It needs about '
                              '${(spec.installSpaceMb / 1024).toStringAsFixed(1)} GB of free space '
                              'while it installs.',
                              style: _small,
                            ),
                            const SizedBox(height: 14),
                            ..._progress(s, mb),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('No internet here? Copy the file',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(
                              'On a computer, download ${spec.name}.zip from alphacephei.com/vosk/models. '
                              'Connect the phone with a USB cable and copy the zip into '
                              '${_copyFolder ?? "the app's folder"}. Then tap the button below.',
                              style: _small,
                            ),
                            const SizedBox(height: 10),
                            ChunkyButton(
                              label: 'Check for a copied file',
                              style: ChunkyStyle.ghost,
                              fontSize: 16,
                              onPressed: s.isBusy ? null : _model.installCopied,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Filipino speech model © 2020 Federico Ang, CC BY-NC-SA 4.0 '
                        '(non-commercial use only).',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: s.isReady
                    ? ChunkyButton(
                        label: "📖 Let's read!",
                        style: ChunkyStyle.sun,
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    : TextButton(
                        onPressed: _notNow,
                        child: const Text('Not now (read by tapping)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _progress(ModelStatus s, int Function(int) mb) => switch (s.phase) {
        ModelPhase.ready => [
            const Text('✓ Filipino listening is ready!',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.green)),
          ],
        ModelPhase.downloading => [
            ProgressBar(value: s.progress ?? 0, color: AppColors.teal),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text('Downloading… ${mb(s.received)} of ${mb(s.total)} MB',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                TextButton(onPressed: _model.cancel, child: const Text('Cancel')),
              ],
            ),
          ],
        ModelPhase.verifying || ModelPhase.unpacking || ModelPhase.checking => [
            const LinearProgressIndicator(minHeight: 10, color: AppColors.teal),
            const SizedBox(height: 6),
            Text(
              switch (s.phase) {
                ModelPhase.verifying => 'Checking the file…',
                ModelPhase.unpacking => 'Unpacking… (about a minute on slower phones)',
                _ => 'Looking on the phone…',
              },
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ModelPhase.missing || ModelPhase.failed => [
            if (s.error != null) ...[
              Text(s.error!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.coral)),
              const SizedBox(height: 8),
            ],
            ChunkyButton(
              label: s.error == null ? 'Download (${filipinoModel.sizeMb} MB)' : 'Try again',
              fontSize: 17,
              onPressed: _model.download,
            ),
          ],
      };
}
