import 'agent_config.dart';
import 'mastery.dart';
import 'philiri.dart';

/// The bits of a past session the teacher flag needs.
class SessionSummary {
  const SessionSummary({required this.level, this.patternsPracticed = const {}});

  final PhilIriLevel level;

  /// Sound patterns that appeared in the words of this session.
  final Set<String> patternsPracticed;
}

/// Teacher flag (AGENT_SPEC §10).
class TeacherFlagger {
  const TeacherFlagger([this.config = const AgentConfig()]);

  final AgentConfig config;

  /// Returns the reasons to flag (empty = no flag).
  /// [sessions] are ordered oldest → newest.
  List<String> reasons({
    required List<SessionSummary> sessions,
    required SoundMastery mastery,
  }) {
    final reasons = <String>[];

    final window = sessions.length <= config.flagWindowSessions
        ? sessions
        : sessions.sublist(sessions.length - config.flagWindowSessions);
    final frustrations =
        window.where((s) => s.level == PhilIriLevel.frustration).length;
    if (frustrations >= config.flagFrustrationCount) {
      reasons.add(
        '$frustrations of the last ${window.length} sessions were Frustration',
      );
    }

    final practiced = <String, int>{};
    for (final s in sessions) {
      for (final p in s.patternsPracticed) {
        practiced[p] = (practiced[p] ?? 0) + 1;
      }
    }
    for (final MapEntry(key: pattern, value: count) in practiced.entries) {
      if (count >= config.flagNeedsHelpAfterSessions &&
          mastery.statusOf(pattern) == MasteryStatus.needsHelp) {
        reasons.add('$pattern still needs help after $count sessions');
      }
    }
    return reasons;
  }

  bool shouldFlag({
    required List<SessionSummary> sessions,
    required SoundMastery mastery,
  }) =>
      reasons(sessions: sessions, mastery: mastery).isNotEmpty;
}
