// lib/core/models/question_model.dart
//
// Admin (questions.php / daily_practice.php) returns:
// {
//   "id": 1,
//   "question": "...",
//   "options": { "a":"...", "b":"...", "c":"...", "d":"..." },
//   "correct": "a",          // lowercase letter
//   "explanation": "...",
//   "difficulty": "easy|medium|hard",
//   "time_limit": 30
// }
//
// We tolerate the older flat shape (option_a, correct_option, question_text) too.

class QuestionModel {
  final int id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  /// Correct option as 0/1/2/3 (A/B/C/D index)
  final int correctIndex;
  final String explanation;
  final String difficulty;
  final String imageUrl;
  final int timeLimit;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.imageUrl,
    required this.timeLimit,
  });

  String get correctLetter {
    const letters = ['A', 'B', 'C', 'D'];
    if (correctIndex < 0 || correctIndex >= letters.length) return 'A';
    return letters[correctIndex];
  }

  List<String> get options => [optionA, optionB, optionC, optionD];

  factory QuestionModel.fromJson(Map<String, dynamic> j) {
    // ── Question text (new key first, fall back to old)
    final qText = (j['question'] ?? j['question_text'] ?? '').toString();

    // ── Options
    String a = '', b = '', c = '', d = '';
    final opt = j['options'];
    if (opt is Map) {
      a = (opt['a'] ?? opt['A'] ?? '').toString();
      b = (opt['b'] ?? opt['B'] ?? '').toString();
      c = (opt['c'] ?? opt['C'] ?? '').toString();
      d = (opt['d'] ?? opt['D'] ?? '').toString();
    } else if (opt is List && opt.length >= 4) {
      a = '${opt[0]}';
      b = '${opt[1]}';
      c = '${opt[2]}';
      d = '${opt[3]}';
    } else {
      a = (j['option_a'] ?? '').toString();
      b = (j['option_b'] ?? '').toString();
      c = (j['option_c'] ?? '').toString();
      d = (j['option_d'] ?? '').toString();
    }

    // ── Correct (admin sends letter "a"/"b"/"c"/"d", legacy may send int or "A")
    int correctIdx = 0;
    final raw = j['correct'] ?? j['correct_option'] ?? j['correct_index'];
    if (raw is int) {
      correctIdx = raw;
    } else if (raw is num) {
      correctIdx = raw.toInt();
    } else if (raw is String) {
      final s = raw.trim().toLowerCase();
      switch (s) {
        case 'a':
        case '0':
          correctIdx = 0;
          break;
        case 'b':
        case '1':
          correctIdx = 1;
          break;
        case 'c':
        case '2':
          correctIdx = 2;
          break;
        case 'd':
        case '3':
          correctIdx = 3;
          break;
        default:
          correctIdx = 0;
      }
    }

    return QuestionModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      questionText: qText,
      optionA: a,
      optionB: b,
      optionC: c,
      optionD: d,
      correctIndex: correctIdx.clamp(0, 3),
      explanation: (j['explanation'] ?? '').toString(),
      difficulty: (j['difficulty'] ?? 'medium').toString(),
      imageUrl: (j['image_url'] ?? '').toString(),
      timeLimit: (j['time_limit'] as num?)?.toInt() ?? 30,
    );
  }
}
