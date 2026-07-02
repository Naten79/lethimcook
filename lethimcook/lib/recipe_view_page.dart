import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'recipe.dart';
import 'edit_recipe_page.dart';
import 'app_theme.dart';
import 'cart_item.dart';
import 'cart_service.dart';

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

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _launchTimer(int minutes) async {
    if (!Platform.isAndroid) return;
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_TIMER',
      arguments: {
        'android.intent.extra.alarm.LENGTH': minutes * 60,
        'android.intent.extra.alarm.MESSAGE': recipe.title,
        'android.intent.extra.alarm.SKIP_UI': false,
      },
    );
    final canResolve = await intent.canResolveActivity();
    if (canResolve != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune application minuteur trouvée sur cet appareil.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    await intent.launch();
  }

  Future<void> _shareRecipe() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharePreviewSheet(recipe: recipe),
    );
  }

  Future<void> _addToCart() async {
    if (recipe.ingredients.isEmpty) return;
    final items = recipe.ingredients.map((ing) {
      final qty = recipe.servings > 0
          ? ing.quantity * currentServings / recipe.servings
          : ing.quantity;
      return CartItem(name: ing.name, quantity: qty, unit: ing.unit);
    }).toList();
    await CartService.addIngredients(items);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${items.length} ingrédient${items.length > 1 ? 's' : ''} ajouté${items.length > 1 ? 's' : ''} au panier'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchTimer(recipe.cookTime ?? 20),
        backgroundColor: kPrimary,
        icon: const Icon(Icons.timer_outlined, color: Colors.white),
        label: const Text('Minuteur',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kBackground,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _shareRecipe,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.share_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
              if (recipe.ingredients.isNotEmpty)
                GestureDetector(
                  onTap: _addToCart,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.shopping_basket_outlined,
                        color: Colors.white, size: 18),
                  ),
                ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditRecipePage(recipe: recipe)),
                  );
                  if (result == true) Navigator.pop(context, true);
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text('Modifier',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 120, 14),
              title: Text(
                recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(0, 1)),
                    Shadow(blurRadius: 12, color: Colors.black54, offset: Offset(0, 2)),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  recipe.imagePath != null
                      ? Image.file(File(recipe.imagePath!), fit: BoxFit.cover)
                      : Image.asset('assets/default_recipe.jpg',
                          fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              typeColor(recipe.type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recipe.type[0].toUpperCase() +
                              recipe.type.substring(1),
                          style: TextStyle(
                            color: typeColor(recipe.type),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ServingsBtn(
                              icon: Icons.remove,
                              onPressed: currentServings > 0.5
                                  ? () => setState(
                                      () => currentServings -= 0.5)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined,
                                      color: kPrimary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _fmt(currentServings),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: kTextPrimary),
                                  ),
                                ],
                              ),
                            ),
                            _ServingsBtn(
                              icon: Icons.add,
                              onPressed: () =>
                                  setState(() => currentServings += 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Chips temps
                  if (recipe.prepTime != null || recipe.restTime != null || recipe.cookTime != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (recipe.prepTime != null && recipe.prepTime! > 0)
                          _TimeChip(
                            icon: Icons.cut_outlined,
                            label: 'Prépa',
                            minutes: recipe.prepTime!,
                            color: const Color(0xFF2196F3),
                          ),
                        if (recipe.restTime != null && recipe.restTime! > 0)
                          _TimeChip(
                            icon: Icons.hourglass_empty_rounded,
                            label: 'Repos',
                            minutes: recipe.restTime!,
                            color: const Color(0xFF9C27B0),
                          ),
                        if (recipe.cookTime != null && recipe.cookTime! > 0)
                          _TimeChip(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Cuisson',
                            minutes: recipe.cookTime!,
                            color: const Color(0xFFFF6B00),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Ingrédients
                  const _SectionHeader(
                      title: 'Ingrédients',
                      icon: Icons.shopping_basket_outlined),
                  const SizedBox(height: 12),
                  recipe.ingredients.isEmpty
                      ? const _EmptyHint(text: 'Aucun ingrédient renseigné.')
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: recipe.ingredients
                                .asMap()
                                .entries
                                .map((entry) {
                              final i = entry.key;
                              final ing = entry.value;
                              final isLast =
                                  i == recipe.ingredients.length - 1;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : const Border(
                                          bottom: BorderSide(
                                              color: kDivider, width: 1)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                          color: kPrimary,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ing.display(
                                          forServings: currentServings,
                                          baseServings:
                                              recipe.servings.toDouble(),
                                        ),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: kTextPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                  const SizedBox(height: 28),

                  // Étapes
                  const _SectionHeader(
                      title: 'Étapes',
                      icon: Icons.format_list_numbered),
                  const SizedBox(height: 12),
                  if (recipe.steps.isEmpty)
                    const _EmptyHint(text: 'Aucune étape renseignée.')
                  else
                    ...recipe.steps.asMap().entries.map((entry) {
                      final i = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(step.text,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: kTextPrimary)),
                                    if (step.timerMinutes != null) ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _launchTimer(step.timerMinutes!),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF3E0),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.timer_outlined,
                                                  size: 13,
                                                  color: Colors.orange.shade700),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${step.timerMinutes} min',
                                                style: TextStyle(
                                                    color: Colors.orange.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
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
                  const SizedBox(height: 28),

                  // Conseils
                  if (recipe.remarks.isNotEmpty) ...[
                    const _SectionHeader(
                        title: 'Conseils', icon: Icons.lightbulb_outline),
                    const SizedBox(height: 12),
                    ...recipe.remarks.map((remark) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFFFE082), width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb,
                                    color: Colors.amber.shade600, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(remark,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: kTextPrimary,
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip temps ────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int minutes;
  final Color color;

  const _TimeChip({
    required this.icon,
    required this.label,
    required this.minutes,
    required this.color,
  });

  String _fmt() {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label · ${_fmt()}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Widgets communs ───────────────────────────────────────────────────────────

class _ServingsBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _ServingsBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 18,
              color: onPressed == null ? Colors.grey : kPrimary),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPrimary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              letterSpacing: -0.3),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: const TextStyle(color: kTextSecondary, fontSize: 14)),
    );
  }
}

// ── Bottom sheet partage ──────────────────────────────────────────────────────

class _SharePreviewSheet extends StatefulWidget {
  final Recipe recipe;
  const _SharePreviewSheet({required this.recipe});

  @override
  State<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<_SharePreviewSheet> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _capture() async {
    setState(() => _sharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final safeName = widget.recipe.title
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim()
          .replaceAll(' ', '_')
          .toLowerCase();
      final file =
          File('${dir.path}/recette_$safeName.png');
      await file.writeAsBytes(bytes);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: widget.recipe.title,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    return Container(
      height: maxH,
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: kDivider, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Text('Aperçu',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _sharing ? null : _capture,
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share_outlined, size: 18),
                  label: Text(_sharing ? 'Génération…' : 'Partager'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: RepaintBoundary(
                key: _cardKey,
                child: _RecipeShareCard(recipe: widget.recipe),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte visuelle de la recette ──────────────────────────────────────────────

class _RecipeShareCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeShareCard({required this.recipe});

  static String _fmtTime(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: recipe.imagePath != null
                ? Image.file(File(recipe.imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover)
                : Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(Icons.local_fire_department,
                        color: Colors.white.withValues(alpha: 0.25),
                        size: 80),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor(recipe.type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recipe.type[0].toUpperCase() + recipe.type.substring(1),
                    style: TextStyle(
                        color: typeColor(recipe.type),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  recipe.title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: kTextPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.people_alt_outlined,
                      color: kTextSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.servings} personne${recipe.servings > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: kTextSecondary, fontSize: 13),
                  ),
                ]),
                if (recipe.prepTime != null ||
                    recipe.cookTime != null ||
                    recipe.restTime != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (recipe.prepTime != null && recipe.prepTime! > 0)
                        _ShareChip(
                          icon: Icons.cut_outlined,
                          label: 'Prépa · ${_fmtTime(recipe.prepTime!)}',
                          color: const Color(0xFF2196F3),
                        ),
                      if (recipe.restTime != null && recipe.restTime! > 0)
                        _ShareChip(
                          icon: Icons.hourglass_empty_rounded,
                          label: 'Repos · ${_fmtTime(recipe.restTime!)}',
                          color: const Color(0xFF9C27B0),
                        ),
                      if (recipe.cookTime != null && recipe.cookTime! > 0)
                        _ShareChip(
                          icon: Icons.local_fire_department_outlined,
                          label:
                              'Cuisson · ${_fmtTime(recipe.cookTime!)}',
                          color: const Color(0xFFFF6B00),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Container(height: 1, color: kDivider),
                const SizedBox(height: 16),
                if (recipe.ingredients.isNotEmpty) ...[
                  _ShareSection(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Ingrédients'),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map((ing) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: CircleAvatar(
                                  radius: 2.5,
                                  backgroundColor: kPrimary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(ing.display(),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextPrimary,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Container(height: 1, color: kDivider),
                  const SizedBox(height: 16),
                ],
                if (recipe.steps.isNotEmpty) ...[
                  _ShareSection(
                      icon: Icons.format_list_numbered,
                      title: 'Étapes'),
                  const SizedBox(height: 10),
                  ...recipe.steps.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text('${entry.key + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(entry.value.text,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextPrimary,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
                if (recipe.remarks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(height: 1, color: kDivider),
                  const SizedBox(height: 16),
                  _ShareSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Conseils',
                      color: const Color(0xFFFFB300)),
                  const SizedBox(height: 10),
                  ...recipe.remarks.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.lightbulb,
                                  color: Color(0xFFFFB300), size: 13),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(r,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextPrimary,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 16),
                Container(height: 1, color: kDivider),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.local_fire_department,
                        color: kPrimary, size: 13),
                    SizedBox(width: 3),
                    Text('LetHimCook',
                        style: TextStyle(
                            fontSize: 11,
                            color: kTextSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _ShareSection(
      {required this.icon,
      required this.title,
      this.color = kPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 6),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kTextPrimary)),
    ]);
  }
}

class _ShareChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ShareChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
