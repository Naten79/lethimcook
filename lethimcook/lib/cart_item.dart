class CartItem {
  final String id;
  String name;
  double quantity;
  String? unit;
  bool checked;

  CartItem({
    String? id,
    required this.name,
    required this.quantity,
    this.unit,
    this.checked = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  String get display {
    final q = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    if (unit != null && unit!.isNotEmpty) return '$q ${unit!} de $name';
    return '$q $name';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'checked': checked,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        id: map['id'] as String,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String?,
        checked: map['checked'] as bool? ?? false,
      );
}
