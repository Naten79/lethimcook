import 'dart:convert';
import 'ingredient.dart';
import 'recipe_step.dart';

class Recipe {
  String? id;
  String title;
  String type;
  String? imagePath;
  List<Ingredient> ingredients;
  List<RecipeStep> steps;
  List<String> remarks;
  int servings;
  int? prepTime;  // minutes
  int? restTime;  // minutes
  int? cookTime;  // minutes

  Recipe({
    this.id,
    required this.title,
    required this.type,
    this.imagePath,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    List<String>? remarks,
    this.servings = 4,
    this.prepTime,
    this.restTime,
    this.cookTime,
  })  : ingredients = ingredients ?? [],
        steps = steps ?? [],
        remarks = remarks ?? [];

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'type': type,
      'image_path': imagePath,
      'ingredients': jsonEncode(ingredients.map((i) => i.toMap()).toList()),
      'steps': jsonEncode(steps.map((s) => s.toMap()).toList()),
      'remarks': jsonEncode(remarks),
      'servings': servings,
      'prep_time': prepTime,
      'rest_time': restTime,
      'cook_time': cookTime,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    List<Ingredient> ingredientList = [];
    List<RecipeStep> stepList = [];
    List<String> remarkList = [];

    if (map['ingredients'] != null) {
      try {
        final decoded = jsonDecode(map['ingredients'] as String) as List;
        ingredientList = decoded.map((i) => Ingredient.fromMap(i)).toList();
      } catch (_) {}
    }
    if (map['steps'] != null) {
      try {
        final decoded = jsonDecode(map['steps'] as String) as List;
        stepList = decoded.map((s) => RecipeStep.fromMap(s)).toList();
      } catch (_) {}
    }
    if (map['remarks'] != null) {
      try {
        final decoded = jsonDecode(map['remarks'] as String) as List;
        remarkList = decoded.map((r) => r.toString()).toList();
      } catch (_) {}
    }

    return Recipe(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      imagePath: map['image_path'],
      ingredients: ingredientList,
      steps: stepList,
      remarks: remarkList,
      servings: (map['servings'] as num?)?.toInt() ?? 4,
      prepTime: (map['prep_time'] as num?)?.toInt(),
      restTime: (map['rest_time'] as num?)?.toInt(),
      cookTime: (map['cook_time'] as num?)?.toInt(),
    );
  }
}
