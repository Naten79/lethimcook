import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'add_recipe_page.dart';
import 'recipe_view_page.dart';
import 'import_recipe_page.dart';
import 'cart_page.dart';
import 'settings_page.dart';
import 'settings_service.dart';
import 'database.dart';
import 'recipe.dart';
import 'app_theme.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://srysgkonajcpddbtjczi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyeXNna29uYWpjcGRkYnRqY3ppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2Mjg2ODEsImV4cCI6MjA5MDIwNDY4MX0.coGk83rmvqWbI__0nlbt-ZAvwGwEfguxTrNoQ2pSi_Q',
  );
  runApp(const LetHimCookApp());
}

class LetHimCookApp extends StatelessWidget {
  const LetHimCookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LetHimCook',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainNavigation(),
    );
  }
}

// ── Navigation principale ─────────────────────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _recipeListKey = GlobalKey<_RecipeListPageState>();
  final _cartKey = GlobalKey<CartPageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RecipeListPage(key: _recipeListKey),
          CartPage(key: _cartKey),
          SettingsPage(onDisplayChanged: () => _recipeListKey.currentState?.reloadSettings()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) _cartKey.currentState?.reload();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: kPrimary),
            label: 'Recettes',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket, color: kPrimary),
            label: 'Panier',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: kPrimary),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({Key? key}) : super(key: key);

  @override
  _RecipeListPageState createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  List<Recipe> recipes = [];
  String selectedFilter = 'all';
  String _searchQuery = '';
  bool _loading = true;
  bool _compact = true;
  bool _showSearch = false;
  bool _scrolledDown = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const List<(String, String)> _filters = [
    ('all', 'Toutes'),
    ('entrée', 'Entrées'),
    ('plat', 'Plats'),
    ('dessert', 'Desserts'),
    ('autre', 'Autres'),
  ];

  @override
  void initState() {
    super.initState();
    loadRecipes();
    _loadSettings();
    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.offset > 60;
      if (scrolled != _scrolledDown) setState(() => _scrolledDown = scrolled);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> loadRecipes() async {
    setState(() => _loading = true);
    final data = await RecipeDatabase.instance.getAllRecipes();
    if (mounted) setState(() { recipes = data; _loading = false; });
  }

  Future<void> _loadSettings() async {
    final v = await SettingsService.isCompact();
    if (mounted) setState(() => _compact = v);
  }

  void reloadSettings() => _loadSettings();

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    final filtered = recipes.where((r) {
      final matchType = selectedFilter == 'all' || r.type.toLowerCase() == selectedFilter;
      final matchSearch = q.isEmpty || r.title.toLowerCase().contains(q);
      return matchType && matchSearch;
    }).toList();

    final currentLabel = _filters.firstWhere((f) => f.$1 == selectedFilter).$2;
    final searchVisible = _showSearch && !_scrolledDown;

    return Scaffold(
      body: Stack(children: [IgnorePointer(child: _RecipeDoodles()), SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 4, 8),
              child: Row(
                children: [
                  Text(
                    'Mes recettes',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      fontStyle: FontStyle.italic,
                      color: kTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) => setState(() => selectedFilter = v),
                    itemBuilder: (_) => _filters
                        .map((f) => PopupMenuItem(
                              value: f.$1,
                              child: Text(
                                f.$2,
                                style: TextStyle(
                                  fontWeight: selectedFilter == f.$1
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: selectedFilter == f.$1
                                      ? kPrimary
                                      : kTextPrimary,
                                ),
                              ),
                            ))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedFilter == 'all'
                            ? Colors.white
                            : kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selectedFilter == 'all' ? kBorder : kPrimary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selectedFilter == 'all'
                                  ? kTextPrimary
                                  : kPrimary,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              size: 18,
                              color: selectedFilter == 'all'
                                  ? kTextSecondary
                                  : kPrimary),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showSearch ? Icons.close : Icons.search,
                      color: _showSearch ? kPrimary : kTextSecondary,
                    ),
                    onPressed: _toggleSearch,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: kPrimary),
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddRecipePage()),
                      );
                      if (result == true) loadRecipes();
                    },
                  ),
                  IconButton(
                    tooltip: 'Importer depuis Marmiton ou JOW',
                    icon: const Icon(Icons.download_rounded, color: kPrimary),
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ImportRecipePage()),
                      );
                      if (result == true) loadRecipes();
                    },
                  ),
                ],
              ),
            ),
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: searchVisible ? 60 : 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: _showSearch,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une recette…',
                      prefixIcon:
                          const Icon(Icons.search, color: kTextSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close,
                                  color: kTextSecondary, size: 18),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimary))
                  : filtered.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _compact ? 2 : 1,
                            childAspectRatio: _compact ? 0.72 : 1.55,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _RecipeCard(
                            recipe: filtered[index],
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeViewPage(recipe: filtered[index]),
                                ),
                              );
                              if (result == true) loadRecipes();
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      ]),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = typeColor(recipe.type);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            recipe.imagePath != null
                ? Image.file(File(recipe.imagePath!), fit: BoxFit.cover)
                : Image.asset('assets/default_recipe.jpg', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.25, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.type[0].toUpperCase() + recipe.type.substring(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black87, offset: Offset(0, 1)),
                          Shadow(blurRadius: 16, color: Colors.black54, offset: Offset(0, 2)),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.servings} pers.',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_outlined,
                size: 48, color: Color(0xFFD0C8C0)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune recette',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez votre première recette !',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


// ── Doodles flottants ─────────────────────────────────────────────────────────

class _RecipeDoodles extends StatelessWidget {
  const _RecipeDoodles();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            top: 72, right: 18,
            child: _FloatingDoodle(
              duration: const Duration(seconds: 6),
              amplitude: 6,
              phase: 0.0,
              child: Transform.rotate(
                angle: 0.15,
                child: Opacity(
                  opacity: 0.13,
                  child: SizedBox(
                    width: 44, height: 60,
                    child: CustomPaint(painter: _LeafPainter()),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 260, left: 10,
            child: _FloatingDoodle(
              duration: const Duration(seconds: 7),
              amplitude: 5,
              phase: 0.4,
              child: Transform.rotate(
                angle: -0.2,
                child: Opacity(
                  opacity: 0.10,
                  child: SizedBox(
                    width: 28, height: 52,
                    child: CustomPaint(painter: _ChiliPainter()),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 430, right: 22,
            child: _FloatingDoodle(
              duration: const Duration(seconds: 5),
              amplitude: 7,
              phase: 0.7,
              child: Opacity(
                opacity: 0.11,
                child: SizedBox(
                  width: 50, height: 50,
                  child: CustomPaint(painter: _StarAnisePainter()),
                ),
              ),
            ),
          ),
          Positioned(
            top: 560, left: 18,
            child: _FloatingDoodle(
              duration: const Duration(seconds: 8),
              amplitude: 5,
              phase: 0.2,
              child: Transform.rotate(
                angle: 0.3,
                child: Opacity(
                  opacity: 0.09,
                  child: SizedBox(
                    width: 38, height: 52,
                    child: CustomPaint(painter: _MushroomPainter()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingDoodle extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double amplitude;
  final double phase;

  const _FloatingDoodle({
    required this.child,
    required this.duration,
    this.amplitude = 6,
    this.phase = 0,
  });

  @override
  State<_FloatingDoodle> createState() => _FloatingDoodleState();
}

class _FloatingDoodleState extends State<_FloatingDoodle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.phase,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: -widget.amplitude, end: widget.amplitude)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _anim.value), child: child),
      child: widget.child,
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kTextPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final leaf = Path()
      ..moveTo(cx, 0)
      ..cubicTo(size.width * 1.1, size.height * 0.28,
          size.width * 0.95, size.height * 0.75, cx, size.height)
      ..cubicTo(-size.width * 0.1, size.height * 0.75,
          -size.width * 0.15, size.height * 0.28, cx, 0);
    canvas.drawPath(leaf, p);
    canvas.drawLine(Offset(cx, size.height * 0.05),
        Offset(cx, size.height * 0.95), p..strokeWidth = 1.0);
    for (final t in [0.3, 0.55]) {
      canvas.drawLine(Offset(cx, size.height * t),
          Offset(size.width * 0.82, size.height * (t + 0.18)), p);
      canvas.drawLine(Offset(cx, size.height * t),
          Offset(size.width * 0.18, size.height * (t + 0.18)), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _ChiliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kTextPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Tige
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height * 0.12), p);
    // Corps
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..cubicTo(size.width * 1.15, size.height * 0.15,
          size.width * 1.1, size.height * 0.65, size.width * 0.5, size.height)
      ..cubicTo(-size.width * 0.1, size.height * 0.65,
          -size.width * 0.15, size.height * 0.15, size.width * 0.5, size.height * 0.1);
    canvas.drawPath(body, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _StarAnisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kTextPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width * 0.44;
    final inner = size.width * 0.16;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a1 = (i * 45 - 90) * pi / 180;
      final a2 = ((i * 45 + 22.5) - 90) * pi / 180;
      final ox = cx + outer * cos(a1);
      final oy = cy + outer * sin(a1);
      final ix = cx + inner * cos(a2);
      final iy = cy + inner * sin(a2);
      if (i == 0) path.moveTo(ox, oy); else path.lineTo(ox, oy);
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, p);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.09, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _MushroomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kTextPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Pied
    final stem = Path()
      ..moveTo(size.width * 0.3, size.height)
      ..lineTo(size.width * 0.32, size.height * 0.62)
      ..lineTo(size.width * 0.68, size.height * 0.62)
      ..lineTo(size.width * 0.7, size.height);
    canvas.drawPath(stem, p);
    // Chapeau
    final cap = Path()
      ..moveTo(size.width * 0.05, size.height * 0.62)
      ..cubicTo(0, size.height * 0.2, size.width * 0.15, 0,
          size.width * 0.5, 0)
      ..cubicTo(size.width * 0.85, 0, size.width, size.height * 0.2,
          size.width * 0.95, size.height * 0.62);
    canvas.drawPath(cap, p);
    // Points décoratifs
    for (final dx in [0.3, 0.5, 0.65]) {
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.28),
          size.width * 0.04, p..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
