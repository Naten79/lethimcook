import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_importer.dart';
import 'recipe.dart';
import 'add_recipe_page.dart';
import 'app_theme.dart';

class ImportRecipePage extends StatefulWidget {
  const ImportRecipePage({super.key});

  @override
  State<ImportRecipePage> createState() => _ImportRecipePageState();
}

class _ImportRecipePageState extends State<ImportRecipePage> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Recipe? _preview;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _error = null; _preview = null; });
    try {
      final recipe = await RecipeImporter.fromUrl(url);
      setState(() { _preview = recipe; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openEditor() {
    if (_preview == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecipePage(initialRecipe: _preview!),
      ),
    ).then((result) {
      if (result == true && mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer une recette')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UrlInputCard(
              controller: _urlCtrl,
              loading: _loading,
              error: _error,
              onImport: _import,
            ),
            if (_preview != null) ...[
              const SizedBox(height: 20),
              _PreviewCard(recipe: _preview!),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openEditor,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Modifier et ajouter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── URL input card ─────────────────────────────────────────────────────────

class _UrlInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onImport;

  const _UrlInputCard({
    required this.controller,
    required this.loading,
    required this.error,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🍴', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marmiton · JOW',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: kTextPrimary)),
                  Text('Collez un lien de recette',
                      style: TextStyle(fontSize: 12, color: kTextSecondary)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.content_paste_rounded,
                    color: kTextSecondary, size: 20),
                tooltip: 'Coller depuis le presse-papiers',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    controller.text = data!.text!;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            onSubmitted: (_) => onImport(),
            decoration: const InputDecoration(
              hintText: 'https://www.marmiton.org/… ou https://jow.fr/…',
              prefixIcon: Icon(Icons.link, color: kTextSecondary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onImport,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download_rounded),
              label: Text(loading ? 'Importation en cours…' : 'Importer'),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recipe preview card ────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final Recipe recipe;
  const _PreviewCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF34A853), size: 18),
              SizedBox(width: 8),
              Text('Recette trouvée !',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF34A853),
                      fontSize: 14)),
            ],
          ),
          const Divider(height: 24, color: kDivider),

          // Title
          Text(recipe.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -0.3)),
          const SizedBox(height: 10),

          // Type + servings chips
          Row(
            children: [
              _Chip(
                label: recipe.type[0].toUpperCase() + recipe.type.substring(1),
                color: typeColor(recipe.type),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: '${recipe.servings} personnes',
                color: kPrimary,
                icon: Icons.people_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // No image notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 15, color: Color(0xFFB8860B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'L\'image ne sera pas importée — vous pourrez en ajouter une après.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8B6914)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ingredients
          _SectionLabel(
              icon: Icons.shopping_basket_outlined,
              title: 'Ingrédients',
              count: recipe.ingredients.length),
          const SizedBox(height: 8),
          ...recipe.ingredients.take(6).map((ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: kPrimary, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(ing.display(),
                          style: const TextStyle(
                              fontSize: 13, color: kTextPrimary)),
                    ),
                  ],
                ),
              )),
          if (recipe.ingredients.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 15),
              child: Text(
                  '+ ${recipe.ingredients.length - 6} autres ingrédients…',
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 12)),
            ),
          const SizedBox(height: 16),

          // Steps
          _SectionLabel(
              icon: Icons.format_list_numbered,
              title: 'Étapes',
              count: recipe.steps.length),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  const _SectionLabel(
      {required this.icon, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kPrimary),
        const SizedBox(width: 6),
        Text('$title',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: kTextPrimary)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kPrimary)),
        ),
      ],
    );
  }
}
