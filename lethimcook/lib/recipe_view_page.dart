import 'package:flutter/material.dart';
import 'dart:io';
import 'recipe.dart';
import 'edit_recipe_page.dart';

class RecipeViewPage extends StatefulWidget {
  final Recipe recipe;
  const RecipeViewPage({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeViewPage> createState() => _RecipeViewPageState();
}

class _RecipeViewPageState extends State<RecipeViewPage> {
  late Recipe recipe;
  late double currentServings;

  @override
  void initState() {
    super.initState();
    recipe = widget.recipe;
    currentServings = recipe.servings.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec image en fond
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(recipe.title,
                  style: TextStyle(shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
              background: recipe.imagePath != null
                  ? Image.file(File(recipe.imagePath!), fit: BoxFit.cover)
                  : Image.asset('assets/default_recipe.jpg', fit: BoxFit.cover),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type
                  Chip(
                    label: Text(
                      recipe.type[0].toUpperCase() + recipe.type.substring(1),
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                  SizedBox(height: 16),

                  // Sélecteur de personnes (produit en croix, lecture seule)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.people, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Personnes : ', style: TextStyle(fontSize: 16)),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              if (currentServings > 0.5) {
                                setState(() => currentServings -= 0.5);
                              }
                            },
                          ),
                          Text(
                            currentServings == currentServings.truncateToDouble()
                                ? currentServings.toInt().toString()
                                : currentServings.toStringAsFixed(1),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: Colors.red),
                            onPressed: () => setState(() => currentServings += 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Ingrédients
                  _sectionTitle('Ingrédients'),
                  SizedBox(height: 8),
                  if (recipe.ingredients.isEmpty)
                    Text('Aucun ingrédient renseigné.', style: TextStyle(color: Colors.grey))
                  else
                    ...recipe.ingredients.map((ing) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.red),
                              SizedBox(width: 8),
                              Text(ing.display(
                                forServings: currentServings,
                                baseServings: recipe.servings.toDouble(),
                              )),
                            ],
                          ),
                        )),
                  SizedBox(height: 24),

                  // Étapes
                  _sectionTitle('Étapes'),
                  SizedBox(height: 8),
                  if (recipe.steps.isEmpty)
                    Text('Aucune étape renseignée.', style: TextStyle(color: Colors.grey))
                  else
                    ...recipe.steps.asMap().entries.map((entry) {
                      final i = entry.key;
                      final step = entry.value;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 14,
                                child: Text('${i + 1}',
                                    style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(step.text),
                                    if (step.timerMinutes != null) ...[
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text('${step.timerMinutes} min',
                                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  SizedBox(height: 24),

                  // Remarques
                  if (recipe.remarks.isNotEmpty) ...[
                    _sectionTitle('Remarques'),
                    SizedBox(height: 8),
                    ...recipe.remarks.map((remark) => Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                                SizedBox(width: 8),
                                Expanded(child: Text(remark)),
                              ],
                            ),
                          ),
                        )),
                    SizedBox(height: 24),
                  ],

                  // Espace pour le bouton flottant
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bouton Modifier en bas
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton.icon(
            icon: Icon(Icons.edit, color: Colors.white),
            label: Text('Modifier la recette', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size.fromHeight(48),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditRecipePage(recipe: recipe)),
              );
              if (result == true) {
                // Recharge la recette depuis la DB pour rafraîchir la vue
                Navigator.pop(context, true);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade800),
    );
  }
}
