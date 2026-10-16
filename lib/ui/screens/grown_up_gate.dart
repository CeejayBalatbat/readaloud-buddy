import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// The parent PIN (4 digits), or null when none is set.
class ParentPinNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() =>
      ref.watch(settingsRepositoryProvider).get(SettingKeys.parentPin);

  Future<void> set(String? pin) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (pin == null) {
      await repo.remove(SettingKeys.parentPin);
    } else {
      await repo.set(SettingKeys.parentPin, pin);
    }
    state = AsyncData(pin);
  }
}

final parentPinProvider =
    AsyncNotifierProvider<ParentPinNotifier, String?>(ParentPinNotifier.new);

/// Grown-ups only: shows [child] when there is no PIN, or after the right
/// PIN is entered. It locks again when the screen is left.
class GrownUpGate extends ConsumerStatefulWidget {
  const GrownUpGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GrownUpGate> createState() => _GrownUpGateState();
}

class _GrownUpGateState extends ConsumerState<GrownUpGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final pin = ref.watch(parentPinProvider);
    if (!pin.hasValue) return const Center(child: CircularProgressIndicator());
    if (pin.value == null || _unlocked) return widget.child;
    return PinPad(
      title: 'Grown-ups only',
      subtitle: 'Enter your 4-digit PIN',
      check: (entered) => entered == pin.value,
      onDone: (_) => setState(() => _unlocked = true),
      onForgot: () async {
        if (await _grownUpCheck(context)) {
          await ref.read(parentPinProvider.notifier).set(null);
          if (mounted) setState(() => _unlocked = true);
        }
      },
    );
  }
}

/// "Forgot PIN?": a multiplication a young child can't do yet. Passing it
/// removes the PIN.
Future<bool> _grownUpCheck(BuildContext context) async {
  final r = Random();
  final a = 6 + r.nextInt(4), b = 6 + r.nextInt(4);
  final answer = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Forgot the PIN?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To remove it, answer: what is $a × $b?'),
          TextField(
            controller: answer,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, answer.text.trim() == '${a * b}'),
          child: const Text('Remove PIN'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// A big number pad for a 4-digit PIN.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onDone,
    this.check,
    this.onForgot,
  });

  final String title;
  final String subtitle;

  /// Called with the 4 digits once they pass [check] (if any).
  final ValueChanged<String> onDone;
  final bool Function(String pin)? check;
  final VoidCallback? onForgot;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _entered = '';
  bool _wrong = false;

  void _tap(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _wrong = false;
      _entered += d;
    });
    if (_entered.length == 4) {
      final pin = _entered;
      if (widget.check == null || widget.check!(pin)) {
        widget.onDone(pin);
      } else {
        setState(() {
          _wrong = true;
          _entered = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: 76,
            height: 64,
            child: ChunkyButton(
              label: label,
              style: ChunkyStyle.ghost,
              fontSize: 24,
              padding: const EdgeInsets.all(8),
              onPressed: onTap,
            ),
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 40)),
          Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(_wrong ? "That's not it. Try again." : widget.subtitle,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _wrong ? AppColors.coral : AppColors.ink2)),
          const SizedBox(height: 16),
          Semantics(
            label: '${_entered.length} of 4 digits',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _entered.length ? AppColors.teal : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) key(d, () => _tap(d))],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 88),
              key('0', () => _tap('0')),
              key('⌫', () => setState(() {
                    if (_entered.isNotEmpty) _entered = _entered.substring(0, _entered.length - 1);
                  })),
            ],
          ),
          if (widget.onForgot != null)
            TextButton(onPressed: widget.onForgot, child: const Text('Forgot PIN?')),
        ],
      ),
    );
  }
}

/// Settings card: set, change or remove the parent PIN.
class ParentPinCard extends ConsumerWidget {
  const ParentPinCard({super.key});

  Future<void> _setPin(BuildContext context, WidgetRef ref) async {
    final first = await _askPin(context, 'Choose a 4-digit PIN');
    if (first == null || !context.mounted) return;
    final again = await _askPin(context, 'Enter it again', check: (p) => p == first);
    if (again != null) await ref.read(parentPinProvider.notifier).set(again);
  }

  Future<String?> _askPin(BuildContext context, String subtitle,
          {bool Function(String)? check}) =>
      Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(backgroundColor: AppColors.cream),
          body: PinPad(
            title: 'Grown-up PIN',
            subtitle: subtitle,
            check: check,
            onDone: (pin) => Navigator.of(ctx).pop(pin),
          ),
        ),
      ));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPin = ref.watch(parentPinProvider).value != null;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grown-up PIN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text(
                  hasPin
                      ? 'On: Settings and the weekly summary need the PIN.'
                      : 'Off: anyone can open Settings.',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          if (hasPin)
            TextButton(
              onPressed: () => ref.read(parentPinProvider.notifier).set(null),
              child: const Text('Remove'),
            ),
          AppChip(
            label: hasPin ? 'Change' : 'Set PIN',
            onTap: () => _setPin(context, ref),
          ),
        ],
      ),
    );
  }
}
