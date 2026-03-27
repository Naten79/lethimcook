import 'package:flutter/material.dart';
import 'database.dart';
import 'recipe.dart';
import 'ingredient.dart';
import 'ingredient_editor.dart';
import 'step_editor.dart';
import 'remark_editor.dart';
import 'recipe_step.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddRecipePage extends StatefulWidget {
  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  String? imagePath;
  final titleController = TextEditingController();
  String selectedType = 'autre';
  List<Ingredient> ingredients = [];
  List<RecipeStep> steps = [];
  List<String> remarks = [];
  int servings = 4;
  bool _isSaving = false;

  Future pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => imagePath = pickedFile.path);
  }

  void saveRecipe() async {
    if (titleController.text.trim().isEmpty) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final recipe = Recipe(
        title: titleController.text.trim(),
        type: selectedType,
        imagePath: imagePath,
        ingredients: ingredients,
        steps: steps,
        remarks: remarks,
        servings: servings,
      );
      await RecipeDatabase.instance.insertRecipe(recipe);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nouvelle recette")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 120, height: 120,
                  color: Colors.red.shade100,
                  child: imagePath != null
                      ? Image.file(File(imagePath!), fit: BoxFit.cover)
                      : Image.asset('assets/default_recipe.jpg', fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Nom de la recette"),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Personnes : ', style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() { if (servings > 1) servings--; }),
                ),
                Text('$servings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => servings++),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['entrée', 'plat', 'dessert', 'autre'].map((type) {
                final isSelected = selectedType == type;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.red : Colors.red.shade100),
                  onPressed: () => setState(() => selectedType = type),
                  child: Text(type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                );
              }).toList(),
            ),
            Divider(height: 32),
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
                      onPressed: saveRecipe,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text("Enregistrer", style: TextStyle(color: Colors.white)),
                    ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
