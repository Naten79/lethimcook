class Ingredient {
  double quantity;
  String? unit; // optionnelle (ex: oeuf n'a pas d'unité)
  String name;

  Ingredient({
    required this.quantity,
    this.unit,
    required this.name,
  });

  // Affichage : "1.5 càc de farine" ou "1 oeuf"
  String display({double? forServings, double? baseServings}) {
    double q = quantity;
    if (forServings != null && baseServings != null && baseServings > 0) {
      q = quantity * forServings / baseServings;
    }
    // Affiche sans décimale si entier (1.0 → "1")
    final qStr = q == q.truncateToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);
    if (unit != null && unit!.trim().isNotEmpty) {
      return '$qStr ${unit!} de $name';
    }
    return '$qStr $name';
  }

  // Sérialisation en JSON string pour Supabase
  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'unit': unit,
      'name': name,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      name: map['name'],
    );
  }
}
