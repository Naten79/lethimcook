import 'package:flutter/material.dart';

class RemarkEditor extends StatefulWidget {
  final List<String> remarks;
  final ValueChanged<List<String>> onChanged;

  const RemarkEditor({Key? key, required this.remarks, required this.onChanged})
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

  void _openRemarkDialog({String? existing, int? index}) {
    final controller = TextEditingController(text: existing ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Ajouter une remarque' : 'Modifier la remarque'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Remarque'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final text = controller.text.trim();
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
            child: Text('Valider', style: TextStyle(color: Colors.white)),
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
        Text('Remarques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        if (_remarks.isEmpty)
          Text('Aucune remarque.', style: TextStyle(color: Colors.grey)),
        ..._remarks.asMap().entries.map((entry) {
          final i = entry.key;
          final remark = entry.value;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            color: Colors.amber.shade50,
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
              title: Text(remark),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade300, size: 20),
                onPressed: () {
                  setState(() => _remarks.removeAt(i));
                  widget.onChanged(_remarks);
                },
              ),
              onTap: () => _openRemarkDialog(existing: remark, index: i),
            ),
          );
        }),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openRemarkDialog(),
          icon: Icon(Icons.add, color: Colors.red),
          label: Text('Ajouter une remarque', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)),
        ),
      ],
    );
  }
}
