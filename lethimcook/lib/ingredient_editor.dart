import 'package:flutter/material.dart';
import 'ingredient.dart';
import 'app_theme.dart';

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

  void _openDialog({Ingredient? existing, int? index}) {
    final qtyCtrl = TextEditingController(
      text: existing != null
          ? (existing.quantity == existing.quantity.truncateToDouble()
              ? existing.quantity.toInt().toString()
              : existing.quantity.toString())
          : '',
    );
    final unitCtrl = TextEditingController(text: existing?.unit ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Ajouter un ingrédient' : 'Modifier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantité (ex: 1.5)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(
                labelText: 'Unité (optionnel)',
                hintText: 'càc, g, ml…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Ingrédient (ex: farine)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(
                  qtyCtrl.text.replaceAll(',', '.'));
              final name = nameCtrl.text.trim();
              if (qty == null || name.isEmpty) return;
              final ing = Ingredient(
                quantity: qty,
                unit: unitCtrl.text.trim().isEmpty
                    ? null
                    : unitCtrl.text.trim(),
                name: name,
              );
              setState(() {
                if (index != null) {
                  _ingredients[index] = ing;
                } else {
                  _ingredients.add(ing);
                }
              });
              widget.onChanged(_ingredients);
              Navigator.pop(ctx);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingrédients',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary)),
        const SizedBox(height: 10),
        if (_ingredients.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Aucun ingrédient ajouté.',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
          ),
        ..._ingredients.asMap().entries.map((entry) {
          final i = entry.key;
          final ing = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: kPrimary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(ing.display(),
                      style: const TextStyle(
                          fontSize: 14, color: kTextPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: kTextSecondary, size: 18),
                  onPressed: () => _openDialog(existing: ing, index: i),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade300, size: 18),
                  onPressed: () {
                    setState(() => _ingredients.removeAt(i));
                    widget.onChanged(_ingredients);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => _openDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter un ingrédient'),
        ),
      ],
    );
  }
}
