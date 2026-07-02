import 'package:flutter/material.dart';
import 'app_theme.dart';

class RemarkEditor extends StatefulWidget {
  final List<String> remarks;
  final ValueChanged<List<String>> onChanged;

  const RemarkEditor(
      {Key? key, required this.remarks, required this.onChanged})
      : super(key: key);

  @override
  State<RemarkEditor> createState() => _RemarkEditorState();
}

class _RemarkEditorState extends State<RemarkEditor> {
  late List<String> _remarks;

  @override
  void initState() {
    super.initState();
    _remarks = List.from(widget.remarks);
  }

  void _openDialog({String? existing, int? index}) {
    final ctrl = TextEditingController(text: existing ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Ajouter un conseil' : 'Modifier'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Conseil ou remarque'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isEmpty) return;
              setState(() {
                if (index != null) {
                  _remarks[index] = text;
                } else {
                  _remarks.add(text);
                }
              });
              widget.onChanged(_remarks);
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
        const Text('Conseils',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary)),
        const SizedBox(height: 10),
        if (_remarks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Aucun conseil ajouté.',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
          ),
        ..._remarks.asMap().entries.map((entry) {
          final i = entry.key;
          final remark = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(remark,
                      style: const TextStyle(
                          fontSize: 13, color: kTextPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: kTextSecondary, size: 17),
                  onPressed: () => _openDialog(existing: remark, index: i),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade300, size: 17),
                  onPressed: () {
                    setState(() => _remarks.removeAt(i));
                    widget.onChanged(_remarks);
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
          label: const Text('Ajouter un conseil'),
        ),
      ],
    );
  }
}
