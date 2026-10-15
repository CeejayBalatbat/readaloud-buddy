import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/current_learner.dart';
import '../../data/database_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/buddy.dart';
import '../widgets/common.dart';

/// Screen 1: a parent sets up a reader (nickname only, no full name).
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, required this.onCreated});

  /// Called with the new reader, who is now the current reader.
  final void Function(Learner learner) onCreated;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _nickname = TextEditingController();
  final _classCode = TextEditingController();
  int? _grade;
  final _languages = <String>{};
  bool _consent = false;
  bool _saving = false;

  static const _grades = ['Kinder', 'Grade 1', 'Grade 2', 'Grade 3'];

  String get _name => _nickname.text.trim();

  bool get _ready =>
      _name.isNotEmpty && _grade != null && _languages.isNotEmpty && _consent && !_saving;

  @override
  void initState() {
    super.initState();
    _nickname.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nickname.dispose();
    _classCode.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _saving = true);
    // Stored as "EN", "FIL" or "EN,FIL" (DATA_MODEL.md).
    final languages = ['EN', 'FIL'].where(_languages.contains).join(',');
    final code = _classCode.text.trim().toUpperCase();
    final learner = await ref.read(learnerRepositoryProvider).create(
          nickname: _name,
          grade: _grade!,
          languages: languages,
          classCode: code.isEmpty ? null : code,
        );
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.get(SettingKeys.consentDate) == null) {
      await settings.set(SettingKeys.consentDate, DateTime.now().toIso8601String());
    }
    await ref.read(currentLearnerProvider.notifier).select(learner.id);
    if (mounted) widget.onCreated(learner);
  }

  @override
  Widget build(BuildContext context) {
    final who = _name.isEmpty ? 'my child' : _name;
    final whose = _name.isEmpty ? "My child's" : "$_name's";
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Buddy(size: 64),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('For parents and guardians',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink2)),
                                Text("Let's set up a reader",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _Label("Child's nickname"),
                      _Field(controller: _nickname, hint: 'e.g. Mia'),
                      const SizedBox(height: 14),
                      const _Label('Grade'),
                      Row(
                        children: [
                          for (final (i, g) in _grades.indexed) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: AppChip(
                                label: g,
                                selected: _grade == i,
                                fontSize: 15,
                                center: true,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                onTap: () => setState(() => _grade = i),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _Label('Reading language'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final (code, name) in [('EN', 'English'), ('FIL', 'Filipino')])
                            AppChip(
                              label: name,
                              selected: _languages.contains(code),
                              fontSize: 15,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              onTap: () => setState(() => _languages.contains(code)
                                  ? _languages.remove(code)
                                  : _languages.add(code)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _Label('Class code from teacher (optional)'),
                      _Field(
                        controller: _classCode,
                        hint: 'e.g. 2B-SAMPAGUITA',
                        caps: true,
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        checked: _consent,
                        label: 'Consent',
                        child: GestureDetector(
                          onTap: () => setState(() => _consent = !_consent),
                          child: AppCard(
                            color: AppColors.tealLight,
                            flat: true,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _consent ? AppColors.teal : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.teal, width: 2),
                                  ),
                                  child: _consent
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700, height: 1.45),
                                      children: [
                                        TextSpan(
                                            text: 'I agree to let $who use ReadAloud Buddy. '
                                                '$whose voice is '),
                                        const TextSpan(
                                            text: 'processed on this phone only',
                                            style: TextStyle(fontWeight: FontWeight.w900)),
                                        const TextSpan(
                                            text: ' and is never recorded or uploaded. Only the '
                                                'nickname and reading results are saved.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text('Sharing this phone? You can add more readers later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 28),
                child: ChunkyButton(
                  label: 'Start reading check',
                  onPressed: _ready ? _start : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink2)),
      );
}

/// `.field`: white input with a 2px line border.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.caps = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool caps;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 2),
        );
    return TextField(
      controller: controller,
      textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.words,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.teal),
      ),
    );
  }
}
