import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe.dart';

class RecipeDatabase {
  static final RecipeDatabase instance = RecipeDatabase._init();
  RecipeDatabase._init();

  final _client = Supabase.instance.client;

  Future<void> insertRecipe(Recipe recipe) async {
    await _client.from('recipes').insert(recipe.toMap());
  }

  Future<List<Recipe>> getAllRecipes() async {
    final result = await _client
        .from('recipes')
        .select()
        .order('created_at', ascending: false);
    return (result as List).map((map) => Recipe.fromMap(map)).toList();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _client
        .from('recipes')
        .update(recipe.toMap())
        .eq('id', recipe.id!);
  }

  Future<void> deleteRecipe(String id) async {
    await _client.from('recipes').delete().eq('id', id);
  }
}
