import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'recipe.dart';
import 'ingredient.dart';
import 'recipe_step.dart';

class RecipeImporter {
  static Future<Recipe> fromUrl(String rawUrl) async {
    final url = rawUrl.trim();
    if (!url.startsWith('http')) throw Exception('URL invalide.');

    final rawBody = await _fetch(url);
    // Decode common HTML entities so our regexes work regardless of encoding
    final body = rawBody
        .replaceAll('&#x2F;', '/')
        .replaceAll('&#47;', '/')
        .replaceAll('&#x2B;', '+')
        .replaceAll('&#43;', '+')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    // Try JSON-LD first (Schema.org standard)
    final jsonLd = _extractRecipeJsonLd(body);
    if (jsonLd != null) return _parseRecipe(jsonLd);

    // Fallback: Next.js __NEXT_DATA__
    final nextData = _extractNextData(body);
    if (nextData != null) {
      if (url.contains('jow.fr')) return _parseJowNextData(nextData);
      return _parseMarmitonNextData(nextData);
    }

    throw Exception(
        'Aucune recette trouvée sur cette page.\n'
        'Vérifiez que le lien pointe vers une recette Marmiton ou JOW.');
  }

  static Future<String> _fetch(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 403 || response.statusCode == 429) {
        throw Exception(
            'La requête a été bloquée (code ${response.statusCode}).\n'
            'Testez sur Android/iOS — le scraping depuis un navigateur '
            'web est bloqué par CORS/Cloudflare.');
      }
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode} — page inaccessible.');
      }

      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } on TimeoutException {
      throw Exception('Délai dépassé — vérifiez votre connexion.');
    } catch (e) {
      // Re-throw our own exceptions as-is
      if (e is Exception) rethrow;
      // For ClientException, SocketException, etc.
      final msg = e.toString();
      if (msg.contains('Failed to fetch') || msg.contains('CORS')) {
        throw Exception(
            'Impossible depuis un navigateur web (CORS).\n'
            'Lancez l\'app sur Android ou iOS pour importer des recettes.');
      }
      throw Exception('Erreur réseau : $msg');
    }
  }

  // ── Next.js __NEXT_DATA__ (Marmiton fallback) ───────────────────────────

  static Map<String, dynamic>? _extractNextData(String html) {
    final m = RegExp(
      r'<script[^>]*__NEXT_DATA__[^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(html);
    if (m == null) return null;
    try {
      return jsonDecode(m.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Recipe _parseMarmitonNextData(Map<String, dynamic> data) {
    // Try common Next.js page data paths
    final pageProps = _dig(data, ['props', 'pageProps']);
    if (pageProps == null) throw Exception('Structure Marmiton non reconnue.');

    // Marmiton may store recipe under different keys — search broadly
    final recipe = _dig(pageProps, ['recipe']) ??
        _dig(pageProps, ['recipeDetails']) ??
        _dig(pageProps, ['data', 'recipe']) ??
        _findMapWithKey(pageProps, 'ingredients');

    if (recipe == null) throw Exception('Données de recette introuvables.');

    final title = _str(recipe['name'] ?? recipe['title']) ?? 'Recette importée';
    final type = _parseType(recipe['recipeCategory'] ?? recipe['category'] ?? recipe['dishType']);
    final servings = _parseServings(recipe['recipeYield'] ?? recipe['servings'] ?? recipe['people']);
    final ingredients = _parseIngredients(
        recipe['recipeIngredient'] ?? recipe['ingredients']);
    final steps = _parseSteps(
        recipe['recipeInstructions'] ?? recipe['steps'] ?? recipe['instructions']);

    return Recipe(
      title: title,
      type: type,
      imagePath: null,
      ingredients: ingredients,
      steps: steps,
      remarks: [],
      servings: servings,
      prepTime: _parseDuration(recipe['prepTime']),
      cookTime: _parseDuration(recipe['cookTime']),
    );
  }

  // Walk a nested map by key path
  static dynamic _dig(dynamic node, List<String> keys) {
    dynamic current = node;
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  // Find first map that contains a given key anywhere in the tree
  static Map<String, dynamic>? _findMapWithKey(dynamic node, String key) {
    if (node is Map<String, dynamic>) {
      if (node.containsKey(key)) return node;
      for (final v in node.values) {
        final found = _findMapWithKey(v, key);
        if (found != null) return found;
      }
    }
    if (node is List) {
      for (final item in node) {
        final found = _findMapWithKey(item, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  // ── JOW __NEXT_DATA__ ───────────────────────────────────────────────────

  static Recipe _parseJowNextData(Map<String, dynamic> data) {
    final pageProps = _dig(data, ['props', 'pageProps']);
    if (pageProps == null) throw Exception('Structure JOW non reconnue.');

    final recipe = _dig(pageProps, ['recipe']) ??
        _dig(pageProps, ['recipeDetails']) ??
        _dig(pageProps, ['data', 'recipe']) ??
        _findMapWithKey(pageProps, 'ingredients');

    if (recipe == null) throw Exception('Données de recette introuvables (JOW).');

    final title = _str(recipe['name'] ?? recipe['title']) ?? 'Recette importée';
    final servings = _parseServings(
        recipe['servings'] ?? recipe['people'] ?? recipe['portions']);
    final ingredients = _parseJowIngredients(recipe['ingredients']);
    final steps = _parseSteps(
        recipe['steps'] ?? recipe['instructions'] ?? recipe['preparationSteps']);

    return Recipe(
      title: title,
      type: _parseType(recipe['category'] ?? recipe['recipeCategory']),
      imagePath: null,
      ingredients: ingredients,
      steps: steps,
      remarks: [],
      servings: servings,
      prepTime: _parseDuration(recipe['prepTime']),
      cookTime: _parseDuration(recipe['cookTime']),
    );
  }

  static List<Ingredient> _parseJowIngredients(dynamic raw) {
    if (raw is! List) return [];
    final result = <Ingredient>[];
    for (final e in raw) {
      if (e is String) {
        result.add(_parseIngredient(e));
      } else if (e is Map) {
        // JOW format: { ingredient: { name }, quantity, unit: { name } | "g" }
        final name = _str(
                (e['ingredient'] is Map ? e['ingredient']['name'] : null) ??
                e['name'] ??
                e['ingredient']) ??
            '';
        if (name.isEmpty) continue;
        final rawQty = e['quantity'] ?? e['qty'] ?? 1;
        final qty = rawQty is num
            ? rawQty.toDouble()
            : double.tryParse(rawQty.toString()) ?? 1.0;
        final rawUnit = e['unit'];
        final unit = rawUnit is Map
            ? _str(rawUnit['name'] ?? rawUnit['label'])
            : (rawUnit is String && rawUnit.isNotEmpty ? rawUnit : null);
        result.add(Ingredient(quantity: qty, unit: unit, name: name));
      }
    }
    return result;
  }

  // ── JSON-LD extraction ───────────────────────────────────────────────────

  static Map<String, dynamic>? _extractRecipeJsonLd(String html) {
    final scriptRegex = RegExp(
      r'<script[^>]*application/ld\+json[^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    );

    for (final match in scriptRegex.allMatches(html)) {
      final raw = match.group(1)?.trim();
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        final found = _findRecipe(decoded);
        if (found != null) return found;
      } catch (_) {}
    }
    return null;
  }

  static Map<String, dynamic>? _findRecipe(dynamic node) {
    if (node is Map) {
      final type = node['@type'];
      if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
        return Map<String, dynamic>.from(node);
      }
      if (node['@graph'] is List) {
        for (final item in node['@graph'] as List) {
          final r = _findRecipe(item);
          if (r != null) return r;
        }
      }
    }
    if (node is List) {
      for (final item in node) {
        final r = _findRecipe(item);
        if (r != null) return r;
      }
    }
    return null;
  }

  // ── Recipe mapping ───────────────────────────────────────────────────────

  static Recipe _parseRecipe(Map<String, dynamic> j) {
    return Recipe(
      title: _str(j['name']) ?? 'Recette importée',
      type: _parseType(j['recipeCategory']),
      imagePath: null,
      ingredients: _parseIngredients(j['recipeIngredient']),
      steps: _parseSteps(j['recipeInstructions']),
      remarks: _parseRemarks(j['description']),
      servings: _parseServings(j['recipeYield']),
      prepTime: _parseDuration(j['prepTime']),
      cookTime: _parseDuration(j['cookTime']),
    );
  }

  // Parses ISO 8601 durations like "PT30M", "PT1H30M", "P0DT30M"
  static int? _parseDuration(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().toUpperCase();
    final h = RegExp(r'(\d+)H').firstMatch(s);
    final m = RegExp(r'(\d+)M').firstMatch(s);
    final hours = h != null ? int.tryParse(h.group(1)!) ?? 0 : 0;
    final mins = m != null ? int.tryParse(m.group(1)!) ?? 0 : 0;
    final total = hours * 60 + mins;
    return total > 0 ? total : null;
  }

  // ── Field parsers ────────────────────────────────────────────────────────

  static String _parseType(dynamic raw) {
    if (raw == null) return 'plat';
    final s = (raw is List ? raw.first : raw).toString().toLowerCase();
    if (s.contains('dessert')) return 'dessert';
    if (s.contains('entrée') || s.contains('entree')) return 'entrée';
    if (s.contains('plat') || s.contains('principal')) return 'plat';
    return 'autre';
  }

  static int _parseServings(dynamic raw) {
    if (raw == null) return 4;
    final s = (raw is List ? raw.first : raw).toString();
    final m = RegExp(r'\d+').firstMatch(s);
    return m != null ? int.tryParse(m.group(0)!) ?? 4 : 4;
  }

  static List<Ingredient> _parseIngredients(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => _parseIngredient(e.toString()))
        .where((i) => i.name.isNotEmpty)
        .toList();
  }

  static Ingredient _parseIngredient(String text) {
    text = text.trim();
    double qty = 1;
    String? unit;
    String name = text;

    // Extract leading number (1, 1.5, 1,5, 1/2)
    final numM = RegExp(
            r'^(\d+(?:[,.]\d+)?(?:\s+\d+\s*/\s*\d+)?|\d+\s*/\s*\d+)')
        .firstMatch(name);
    if (numM != null) {
      final raw = numM.group(1)!.replaceAll(' ', '');
      if (raw.contains('/')) {
        final p = raw.split('/');
        qty = (double.tryParse(p[0]) ?? 1) / (double.tryParse(p[1]) ?? 1);
      } else {
        qty = double.tryParse(raw.replaceAll(',', '.')) ?? 1;
      }
      name = name.substring(numM.end).trimLeft();
    }

    // Match units (longest first so "cl" doesn't beat "cuillère")
    const units = [
      'cuillère à café', 'cuillère à soupe',
      'c. à c.', 'c. à s.', 'c.à.c.', 'c.à.s.',
      'càc', 'càs',
      'pincées', 'pincée', 'sachets', 'sachet',
      'tranches', 'tranche', 'bouquets', 'bouquet',
      'bottes', 'botte', 'poignées', 'poignée',
      'gousses', 'gousse', 'feuilles', 'feuille',
      'brins', 'brin',
      'kg', 'dl', 'cl', 'ml', 'g', 'l',
    ];

    final lname = name.toLowerCase();
    for (final u in units) {
      if (lname.startsWith(u) &&
          (lname.length == u.length || !_isLetter(lname[u.length]))) {
        unit = name.substring(0, u.length);
        name = name.substring(u.length).trimLeft();
        break;
      }
    }

    // Remove French articles
    name = name
        .replaceFirst(RegExp(r"^(de |d'|du |des |la |le |les )",
            caseSensitive: false), '')
        .trim();

    if (name.isNotEmpty) name = name[0].toUpperCase() + name.substring(1);
    if (name.isEmpty) name = text;

    return Ingredient(quantity: qty, unit: unit, name: name);
  }

  static bool _isLetter(String c) =>
      RegExp(r'[a-zA-ZàâçéèêëîïôûùüæœÀÂÇÉÈÊËÎÏÔÛÙÜÆŒ]').hasMatch(c);

  static List<RecipeStep> _parseSteps(dynamic raw) {
    if (raw == null) return [];
    final items = raw is List ? raw : [raw];
    final steps = <RecipeStep>[];
    for (final item in items) {
      if (item is String) {
        final t = item.trim();
        if (t.isNotEmpty) steps.add(RecipeStep(text: t));
      } else if (item is Map) {
        if (item['@type'] == 'HowToSection' &&
            item['itemListElement'] is List) {
          for (final sub in item['itemListElement'] as List) {
            final t = _str(sub is Map ? sub['text'] : sub)?.trim() ?? '';
            if (t.isNotEmpty) steps.add(RecipeStep(text: t));
          }
        } else {
          final t = _str(item['text'] ?? item['description'] ?? item['step'])?.trim() ?? '';
          if (t.isNotEmpty) steps.add(RecipeStep(text: t));
        }
      }
    }
    return steps;
  }

  static List<String> _parseRemarks(dynamic raw) {
    final desc = _str(raw)?.trim() ?? '';
    if (desc.isEmpty || desc.length > 300) return [];
    return [desc];
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is List && v.isNotEmpty) return v.first.toString();
    return v.toString();
  }
}
