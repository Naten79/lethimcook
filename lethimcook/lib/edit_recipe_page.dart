import 'package:flutter/material.dart';
import 'recipe.dart';
import 'ingredient.dart';
import 'ingredient_editor.dart';
import 'step_editor.dart';
import 'remark_editor.dart';
import 'recipe_step.dart';
import 'database.dart';

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;
  EditRecipePage({required this.recipe});

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  late List<Ingredient> ingredients;
  late List<RecipeStep> steps;
  late List<String> remarks;
  late int baseServings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    ingredients = List.from(widget.recipe.ingredients);
    steps = List.from(widget.recipe.steps);
    remarks = List.from(widget.recipe.remarks);
    baseServings = widget.recipe.servings;
  }

  void saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      widget.recipe.ingredients = ingredients;
      widget.recipe.steps = steps;
      widget.recipe.remarks = remarks;
      widget.recipe.servings = baseServings;
      await RecipeDatabase.instance.updateRecipe(widget.recipe);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifier : ${widget.recipe.title}')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre de personnes de base
            Row(
              children: [
                Text('Personnes (base) : ', style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() { if (baseServings > 1) baseServings--; }),
                ),
                Text('$baseServings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => baseServings++),
                ),
              ],
            ),
            SizedBox(height: 16),

            IngredientEditor(
              ingredients: ingredients,
              onChanged: (updated) => setState(() => ingredients = updated),
            ),
            Divider(height: 32),

            StepEditor(
              steps: steps,
              onChanged: (updated) => setState(() => steps = updated),
            ),
            Divider(height: 32),

            RemarkEditor(
              remarks: remarks,
              onChanged: (updated) => setState(() => remarks = updated),
            ),
            SizedBox(height: 32),

            Center(
              child: _isSaving
                  ? CircularProgressIndicator(color: Colors.red)
                  : ElevatedButton(
                      onPressed: saveChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Enregistrer', style: TextStyle(color: Colors.white)),
                    ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
