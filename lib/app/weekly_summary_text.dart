import 'weekly_summary.dart';

/// The weekly summary's words for the parent, in English or Filipino
/// (the EN / FIL switch on screen 11). Names, never he/she.
class SummaryText {
  const SummaryText(this.summary, {this.filipino = false, this.patterns = const {}});

  final WeeklySummary summary;
  final bool filipino;
  final Map<String, SoundPattern> patterns;

  String get _n => summary.nickname;

  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsFil = ['Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun', 'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis'];

  /// "Oct 10–16", or "Sep 28 – Oct 4" across months.
  String get dates {
    final m = filipino ? _monthsFil : _monthsEn;
    final a = summary.from, b = summary.to;
    return a.month == b.month
        ? '${m[a.month - 1]} ${a.day}–${b.day}'
        : '${m[a.month - 1]} ${a.day} – ${m[b.month - 1]} ${b.day}';
  }

  String get kicker => '${filipino ? 'Lingguhang buod' : 'Weekly summary'} · $dates';
  String get title => filipino ? 'Linggo ng pagbasa ni $_n' : "$_n's reading week";
  String get minutesLabel => filipino ? 'minuto' : 'minutes';
  String get storiesLabel => filipino ? 'kuwento' : 'stories';
  String get wcpmLabel => filipino ? 'salita/minuto' : 'words/min';

  /// "+6", "−2", "±0", or this week's average without a sign.
  String get wcpmValue {
    final change = summary.wcpmChange;
    if (change != null) {
      final r = change.round();
      return r > 0 ? '+$r' : (r < 0 ? '−${-r}' : '±0');
    }
    final w = summary.wcpm;
    return w == null ? '–' : '${w.round()}';
  }

  String get levelTitle => filipino ? 'Antas sa pagbasa' : 'Reading level';
  String get levelBadge {
    final l = summary.level;
    if (summary.topLevel) return filipino ? 'Antas $l · pinakamataas' : 'Level $l · top level';
    if (summary.almostNext) {
      return filipino ? 'Antas $l → malapit na sa ${l + 1}' : 'Level $l → almost ${l + 1}';
    }
    return filipino ? 'Antas $l' : 'Level $l';
  }

  String get celebrateTitle => filipino ? '🎉 Ipagdiwang' : '🎉 Celebrate';
  String get celebrate {
    final words = summary.celebrateWords.map((w) => '"$w"').toList();
    if (words.isNotEmpty) {
      final list = words.length == 1
          ? words.first
          : '${words.sublist(0, words.length - 1).join(', ')} ${filipino ? 'at' : 'and'} ${words.last}';
      return filipino
          ? 'Nabasa ni $_n nang mag-isa ang $list ngayong linggo. Mahirap ang mga ito dati!'
          : '$_n read $list on their own this week. Those were hard before!';
    }
    final s = summary.stories;
    if (s > 0) {
      return filipino
          ? 'Nakabasa si $_n ng $s kuwento ngayong linggo. Malaking tulong ang bawat kuwento!'
          : '$_n read $s ${s == 1 ? 'story' : 'stories'} this week. Every story helps!';
    }
    return filipino
        ? 'Wala pang pagbasa ngayong linggo. Magandang simula ang isang maikling kuwento ngayon!'
        : 'No reading yet this week. A short story today is a great start!';
  }

  String get tipTitle => filipino ? '💡 Subukan sa bahay (2 minuto)' : '💡 Try at home (2 minutes)';
  String get tip {
    final p = patterns[summary.tipPattern];
    if (p == null) {
      return filipino
          ? 'Magbasa nang sabay nang 5 minuto araw-araw. Hayaang ituro ni $_n ang bawat salita.'
          : 'Read together for 5 minutes a day. Let $_n point to each word.';
    }
    final ex = [for (final e in p.examples.take(3)) '"$e"'];
    final two = ex.length == 1 ? ex.first : '${ex[0]} ${filipino ? 'at' : 'and'} ${ex[1]}';
    if (p.code.endsWith('-SW')) {
      final all = ex.length < 3 ? two : '${ex[0]}, ${ex[1]} ${filipino ? 'at' : 'and'} ${ex[2]}';
      return filipino
          ? 'Isulat ang $all sa maliliit na kard. Itago sa bahay at ipabasa kay $_n ang bawat makita.'
          : 'Write $all on small cards. Hide them around the house and let $_n read each one found.';
    }
    if (p.code.endsWith('-ML')) {
      return filipino
          ? 'Pumalakpak kasama si $_n sa bawat pantig ng mahahabang salita tulad ng ${ex.first}.'
          : 'Clap the parts of long words like ${ex.first} together with $_n: one clap per part.';
    }
    return filipino
        ? 'Kapag may nakita kayong salitang tulad ng $two sa karatula o pakete, ipabasa ito kay $_n.'
        : 'When you see words like $two on signs or labels, ask $_n to read them to you.';
  }

  String get printTitle =>
      filipino ? 'I-print ang mahihirap na salita ni $_n' : "Print $_n's tricky words";
  String get printSubtitle => summary.trickyWords.isEmpty
      ? (filipino ? 'Walang mahirap na salita ngayon 🎉' : 'No tricky words right now 🎉')
      : (filipino ? 'Pagsasanay nang walang telepono' : 'Practice without the phone');

  /// On the printed page.
  String get sheetTitle => filipino ? 'Mahihirap na salita ni $_n' : "$_n's tricky words";
  String get sheetHint => filipino
      ? 'Basahin nang sabay ang bawat salita. Takpan, tapos sabihin ulit!'
      : 'Read each word together. Cover it, then say it again!';
}
