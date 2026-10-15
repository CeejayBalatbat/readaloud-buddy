/// Turns the recognizer's growing transcript into new words, one at a time.
///
/// Android sends the whole utterance so far with every partial result
/// ("the", "the cat", "the cats sat"), and may still change the last word.
/// We pass on each word position once: words before the last one as soon
/// as they appear, the last one when the result is final, or earlier if
/// [acceptEarly] says it already matches the word the child should read.
/// A word that changes after it was passed on is not sent again.
class TranscriptTracker {
  int _emitted = 0;

  /// Words of the current utterance already passed on.
  int get emitted => _emitted;

  /// A new utterance started (the recognizer restarted).
  void reset() => _emitted = 0;

  /// Feeds one recognizer result. Calls [emit] for each new word, in order.
  /// When [muted], everything heard so far is skipped (never emitted).
  void update(
    String transcript, {
    required bool isFinal,
    required void Function(String word) emit,
    bool Function(String word)? acceptEarly,
    bool muted = false,
  }) {
    final words = split(transcript);
    if (muted) {
      if (words.length > _emitted) _emitted = words.length;
      return;
    }
    final stable = isFinal ? words.length : words.length - 1;
    while (_emitted < stable) {
      emit(words[_emitted++]);
    }
    if (!isFinal &&
        _emitted == words.length - 1 &&
        acceptEarly != null &&
        acceptEarly(words.last)) {
      emit(words[_emitted++]);
    }
  }

  static const _numbers = {
    '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four',
    '5': 'five', '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine',
    '10': 'ten',
  };

  /// Splits a transcript into words. Recognizers often write small numbers
  /// as digits ("2"), while stories spell them out ("two").
  static List<String> split(String transcript) => [
        for (final w in transcript.trim().split(RegExp(r'\s+')))
          if (w.isNotEmpty) _numbers[w] ?? w,
      ];
}
