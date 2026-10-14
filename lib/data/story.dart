import 'dart:convert';

/// Story content loaded from assets/data/stories.json.
/// Pure Dart (no Flutter imports) so the agent and tests can use it too.

class Story {
  const Story({
    required this.id,
    required this.title,
    required this.language,
    required this.level,
    required this.text,
    required this.words,
    required this.questions,
  });

  final String id; // e.g. "S01"
  final String title;
  final String language; // "EN" or "FIL"
  final int level; // 1–4
  final String text;
  final List<StoryWord> words;
  final List<Question> questions;

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    title: json['title'] as String,
    language: json['language'] as String,
    level: json['level'] as int,
    text: json['text'] as String,
    words: [
      for (final w in json['words'] as List)
        StoryWord.fromJson(w as Map<String, dynamic>),
    ],
    questions: [
      for (final q in json['questions'] as List)
        Question.fromJson(q as Map<String, dynamic>),
    ],
  );
}

class StoryWord {
  const StoryWord({
    required this.position,
    required this.word,
    required this.patterns,
    required this.primaryPattern,
    required this.syllables,
    required this.difficulty,
  });

  final int position; // 1-based
  final String word; // as written, may include capitals
  final List<String> patterns; // sound-pattern codes, e.g. ["EN-SW", "EN-TH"]
  final String primaryPattern; // hardest pattern, used for mastery tracking
  final int syllables;
  final double difficulty; // 0–1

  factory StoryWord.fromJson(Map<String, dynamic> json) => StoryWord(
    position: json['position'] as int,
    word: json['word'] as String,
    patterns: List<String>.from(json['patterns'] as List),
    primaryPattern: json['primary_pattern'] as String,
    syllables: json['syllables'] as int,
    difficulty: (json['difficulty'] as num).toDouble(),
  );
}

class Question {
  const Question({
    required this.id,
    required this.question,
    required this.answer,
    required this.type,
    required this.choices,
  });

  final String id; // e.g. "S01-Q1"
  final String question;
  final String answer;
  final String type; // "Literal" or "Inferential"
  final List<AnswerChoice> choices; // 3 picture answers, exactly one correct

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
    type: json['type'] as String,
    choices: [
      for (final c in json['choices'] as List)
        AnswerChoice.fromJson(c as Map<String, dynamic>),
    ],
  );
}

class AnswerChoice {
  const AnswerChoice({
    required this.text,
    required this.emoji,
    required this.correct,
  });

  final String text;
  final String emoji; // placeholder picture until we have real art
  final bool correct;

  factory AnswerChoice.fromJson(Map<String, dynamic> json) => AnswerChoice(
    text: json['text'] as String,
    emoji: json['emoji'] as String,
    correct: json['correct'] as bool,
  );
}

/// Parses the whole stories.json file.
List<Story> parseStories(String jsonText) => [
  for (final s in jsonDecode(jsonText) as List)
    Story.fromJson(s as Map<String, dynamic>),
];
