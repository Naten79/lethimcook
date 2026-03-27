class RecipeStep {
  String text;
  int? timerMinutes; // optionnel

  RecipeStep({
    required this.text,
    this.timerMinutes,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'timerMinutes': timerMinutes,
      };

  factory RecipeStep.fromMap(Map<String, dynamic> map) => RecipeStep(
        text: map['text'] ?? '',
        timerMinutes: map['timerMinutes'],
      );
}
