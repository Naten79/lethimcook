import 'package:flutter/material.dart';
import 'ingredient.dart';

/// Widget réutilisable pour gérer la liste d'ingrédients
/// Utilisé dans AddRecipePage et EditRecipePage
class IngredientEditor extends StatefulWidget {
  final List<Ingredient> ingredients;
  final ValueChanged<List<Ingredient>> onChanged;

  const IngredientEditor({
    Key? key,
    required this.ingredients,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<IngredientEditor> {
  late List<Ingredient> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.ingredients);
  }

  void _openIngredientDialog({Ingredient? existing, int? index}) {
    final quantityController = TextEditingController(
      text: existing != null
          ? (existing.quantity == existing.quantity.truncateToDouble()
              ? existing.quantity.toInt().toString()
              : existing.quantity.toString())
          : '',
    );
    final unitController = TextEditingController(text: existing?.unit ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Ajouter un ingrédient' : 'Modifier l\'ingrédient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: 'Quantité (ex: 1.5)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 8),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: 'Unité (optionnel)',
                hintText: 'càc, g, ml, ...',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Ingrédient (ex: farine)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final qty = double.tryParse(
                quantityController.text.replaceAll(',', '.'),
              );
              final name = nameController.text.trim();
              if (qty == null || name.isEmpty) return;

              final ingredient = Ingredient(
                quantity: qty,
                unit: unitController.text.trim().isEmpty
                    ? null
                    : unitController.text.trim(),
                name: name,
              );

              setState(() {
                if (index != null) {
                  _ingredients[index] = ingredient;
                } else {
                  _ingredients.add(ingredient);
                }
              });
              widget.onChanged(_ingredients);
              Navigator.pop(ctx);
            },
            child: Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteIngredient(int index) {
    setState(() => _ingredients.removeAt(index));
    widget.onChanged(_ingredients);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingrédients',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        if (_ingredients.isEmpty)
          Text('Aucun ingrédient ajouté.', style: TextStyle(color: Colors.grey)),
        ..._ingredients.asMap().entries.map((entry) {
          final i = entry.key;
          final ing = entry.value;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(ing.display()),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade300, size: 20),
              onPressed: () => _deleteIngredient(i),
            ),
            onTap: () => _openIngredientDialog(existing: ing, index: i),
          );
        }),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openIngredientDialog(),
          icon: Icon(Icons.add, color: Colors.red),
          label: Text('Ajouter un ingrédient', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)),
        ),
      ],
    );
  }
}
