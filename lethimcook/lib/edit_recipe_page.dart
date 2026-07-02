import 'package:flutter/material.dart';
import 'recipe.dart';
import 'ingredient.dart';
import 'ingredient_editor.dart';
import 'step_editor.dart';
import 'remark_editor.dart';
import 'recipe_step.dart';
import 'database.dart';
import 'app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;
  const EditRecipePage({super.key, required this.recipe});

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  late TextEditingController _titleController;
  late String _selectedType;
  late String? _imagePath;
  late List<Ingredient> ingredients;
  late List<RecipeStep> steps;
  late List<String> remarks;
  late int baseServings;
  late int prepTime;
  late int restTime;
  late int cookTime;
  bool _isSaving = false;

  static const _typeOptions = [
    ('entrée', 'Entrée', Icons.eco),
    ('plat', 'Plat', Icons.restaurant),
    ('dessert', 'Dessert', Icons.cake),
    ('autre', 'Autre', Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _selectedType = widget.recipe.type;
    _imagePath = widget.recipe.imagePath;
    ingredients = List.from(widget.recipe.ingredients);
    steps = List.from(widget.recipe.steps);
    remarks = List.from(widget.recipe.remarks);
    baseServings = widget.recipe.servings;
    prepTime = widget.recipe.prepTime ?? 0;
    restTime = widget.recipe.restTime ?? 0;
    cookTime = widget.recipe.cookTime ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer la photo',
          toolbarColor: kPrimary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: kPrimary,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
    if (cropped != null) setState(() => _imagePath = cropped.path);
  }

  void _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      widget.recipe.title = _titleController.text.trim();
      widget.recipe.type = _selectedType;
      widget.recipe.imagePath = _imagePath;
      widget.recipe.ingredients = ingredients;
      widget.recipe.steps = steps;
      widget.recipe.remarks = remarks;
      widget.recipe.servings = baseServings;
      widget.recipe.prepTime = prepTime > 0 ? prepTime : null;
      widget.recipe.restTime = restTime > 0 ? restTime : null;
      widget.recipe.cookTime = cookTime > 0 ? cookTime : null;
      await RecipeDatabase.instance.updateRecipe(widget.recipe);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la recette'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: kPrimary, strokeWidth: 2)))
                : TextButton(
                    onPressed: _save,
                    child: const Text('Enregistrer',
                        style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _imagePath != null
                        ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                        : Image.asset('assets/default_recipe.jpg',
                            fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: kPrimary, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la recette',
                      prefixIcon: Icon(Icons.restaurant_menu,
                          color: kTextSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('TYPE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kTextSecondary,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_typeOptions.length, (i) {
                      final (value, label, icon) = _typeOptions[i];
                      final isSelected = _selectedType == value;
                      final isLast = i == _typeOptions.length - 1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedType = value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected ? kPrimary : kBorder),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon,
                                      size: 20,
                                      color: isSelected
                                          ? Colors.white
                                          : kTextSecondary),
                                  const SizedBox(height: 4),
                                  Text(label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : kTextPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt_outlined,
                            color: kPrimary, size: 20),
                        const SizedBox(width: 10),
                        const Text('Personnes (base)',
                            style: TextStyle(
                                fontSize: 14,
                                color: kTextPrimary,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: kPrimary),
                          onPressed: () => setState(() {
                            if (baseServings > 1) baseServings--;
                          }),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text('$baseServings',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: kPrimary),
                          onPressed: () =>
                              setState(() => baseServings++),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      children: [
                        _TimePickerRow(
                          icon: Icons.cut_outlined,
                          label: 'Préparation',
                          color: const Color(0xFF2196F3),
                          value: prepTime,
                          onChanged: (v) => setState(() => prepTime = v),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: kDivider),
                        _TimePickerRow(
                          icon: Icons.hourglass_empty_rounded,
                          label: 'Repos',
                          color: const Color(0xFF9C27B0),
                          value: restTime,
                          onChanged: (v) => setState(() => restTime = v),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: kDivider),
                        _TimePickerRow(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Cuisson',
                          color: const Color(0xFFFF6B00),
                          value: cookTime,
                          onChanged: (v) => setState(() => cookTime = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _Section(child: IngredientEditor(
                    ingredients: ingredients,
                    onChanged: (v) => setState(() => ingredients = v),
                  )),
                  const SizedBox(height: 14),
                  _Section(child: StepEditor(
                    steps: steps,
                    onChanged: (v) => setState(() => steps = v),
                  )),
                  const SizedBox(height: 14),
                  _Section(child: RemarkEditor(
                    remarks: remarks,
                    onChanged: (v) => setState(() => remarks = v),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  const _TimePickerRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  String _display() {
    if (value == 0) return '—';
    if (value < 60) return '$value min';
    final h = value ~/ 60;
    final m = value % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: kTextPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline,
                color: value >= 5 ? kPrimary : Colors.grey.shade300),
            onPressed: value >= 5 ? () => onChanged(value - 5) : null,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 64,
            child: Text(_display(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: value == 0 ? kTextSecondary : kTextPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kPrimary),
            onPressed: () => onChanged(value + 5),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
