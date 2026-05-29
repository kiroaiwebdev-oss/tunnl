class QuestionModel {
  final int    id;
  final String questionText;
  final String optionA, optionB, optionC, optionD;
  final String correctOption;
  final String explanation;
  final String difficulty;
  final String imageUrl;

  QuestionModel({
    required this.id, required this.questionText,
    required this.optionA, required this.optionB,
    required this.optionC, required this.optionD,
    required this.correctOption, required this.explanation,
    required this.difficulty, required this.imageUrl,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> j) => QuestionModel(
    id:            j['id']             ?? 0,
    questionText:  j['question_text']  ?? '',
    optionA:       j['option_a']       ?? '',
    optionB:       j['option_b']       ?? '',
    optionC:       j['option_c']       ?? '',
    optionD:       j['option_d']       ?? '',
    correctOption: j['correct_option'] ?? 'A',
    explanation:   j['explanation']    ?? '',
    difficulty:    j['difficulty']     ?? 'medium',
    imageUrl:      j['image_url']      ?? '',
  );
}
