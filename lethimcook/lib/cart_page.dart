import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'cart_item.dart';
import 'cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  List<CartItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final items = await CartService.getItems();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _toggleChecked(CartItem item) async {
    await CartService.toggleChecked(item.id);
    await _load();
  }

  Future<void> _remove(String id) async {
    await CartService.removeItem(id);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Tous les articles seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await CartService.clear();
      await _load();
    }
  }

  void _showSheet({CartItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemSheet(
        initial: item,
        onSave: (name, quantity, unit) async {
          if (item == null) {
            await CartService.addItem(CartItem(
              name: name,
              quantity: quantity,
              unit: unit.isEmpty ? null : unit,
            ));
          } else {
            item.name = name;
            item.quantity = quantity;
            item.unit = unit.isEmpty ? null : unit;
            await CartService.updateItem(item);
          }
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unchecked = _items.where((i) => !i.checked).toList();
    final checked = _items.where((i) => i.checked).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 16),
              child: Row(
                children: [
                  Text(
                    'Panier',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      fontStyle: FontStyle.italic,
                      color: kTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (_items.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: kTextSecondary),
                      tooltip: 'Vider le panier',
                      onPressed: _clearAll,
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimary))
                  : _items.isEmpty
                      ? const _EmptyCart()
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          children: [
                            ...unchecked.map((item) => _CartItemTile(
                                  key: ValueKey(item.id),
                                  item: item,
                                  onToggle: () => _toggleChecked(item),
                                  onEdit: () => _showSheet(item: item),
                                  onDelete: () => _remove(item.id),
                                )),
                            if (checked.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 20, 4, 10),
                                child: Row(
                                  children: [
                                    Text(
                                      'Dans le caddie (${checked.length})',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () async {
                                        await CartService.clearChecked();
                                        await _load();
                                      },
                                      child: const Text(
                                        'Tout supprimer',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...checked.map((item) => _CartItemTile(
                                    key: ValueKey(item.id),
                                    item: item,
                                    onToggle: () => _toggleChecked(item),
                                    onEdit: () => _showSheet(item: item),
                                    onDelete: () => _remove(item.id),
                                  )),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSheet(),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Tuile d'un article ────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CartItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: item.checked ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: Checkbox(
            value: item.checked,
            onChanged: (_) => onToggle(),
            activeColor: kPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            item.display,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: item.checked ? kTextSecondary : kTextPrimary,
              decoration:
                  item.checked ? TextDecoration.lineThrough : null,
              decorationColor: kTextSecondary,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: kTextSecondary, size: 18),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_basket_outlined,
                size: 48, color: Color(0xFFD0C8C0)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Panier vide',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des ingrédients depuis une recette\nou manuellement avec le bouton +.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ajouter / modifier ──────────────────────────────────────────

class _ItemSheet extends StatefulWidget {
  final CartItem? initial;
  final Future<void> Function(String name, double quantity, String unit)
      onSave;

  const _ItemSheet({this.initial, required this.onSave});

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _qtyCtrl = TextEditingController(
      text: item == null
          ? '1'
          : (item.quantity == item.quantity.truncateToDouble()
              ? item.quantity.toInt().toString()
              : item.quantity.toStringAsFixed(1)),
    );
    _unitCtrl = TextEditingController(text: item?.unit ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final qty =
        double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1.0;
    setState(() => _saving = true);
    await widget.onSave(name, qty, _unitCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: kDivider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              widget.initial == null ? 'Ajouter un article' : 'Modifier',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Article',
                hintText: 'Ex: Farine',
                prefixIcon: Icon(Icons.shopping_basket_outlined,
                    color: kTextSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      prefixIcon: Icon(Icons.pin_outlined,
                          color: kTextSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unité (optionnel)',
                      hintText: 'g, ml, càs…',
                      prefixIcon: Icon(Icons.straighten_outlined,
                          color: kTextSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: Text(
                    widget.initial == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
