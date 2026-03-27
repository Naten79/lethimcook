import 'package:flutter/material.dart';
import 'recipe_step.dart';

class StepEditor extends StatefulWidget {
  final List<RecipeStep> steps;
  final ValueChanged<List<RecipeStep>> onChanged;

  const StepEditor({Key? key, required this.steps, required this.onChanged})
      : super(key: key);

  @override
  State<StepEditor> createState() => _StepEditorState();
}

class _StepEditorState extends State<StepEditor> {
  late List<RecipeStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = List.from(widget.steps);
  }

  void _openStepDialog({RecipeStep? existing, int? index}) {
    final textController = TextEditingController(text: existing?.text ?? '');
    final timerController = TextEditingController(
      text: existing?.timerMinutes != null ? existing!.timerMinutes.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Ajouter une étape' : 'Modifier l\'étape'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(labelText: 'Description de l\'étape'),
              maxLines: 3,
              autofocus: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: timerController,
              decoration: InputDecoration(
                labelText: 'Timer (minutes, optionnel)',
                hintText: 'ex: 20',
                prefixIcon: Icon(Icons.timer_outlined, color: Colors.red),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isEmpty) return;
              final timer = int.tryParse(timerController.text.trim());
              final step = RecipeStep(text: text, timerMinutes: timer);
              setState(() {
                if (index != null) {
                  _steps[index] = step;
                } else {
                  _steps.add(step);
                }
              });
              widget.onChanged(_steps);
              Navigator.pop(ctx);
            },
            child: Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteStep(int index) {
    setState(() => _steps.removeAt(index));
    widget.onChanged(_steps);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Étapes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        if (_steps.isEmpty)
          Text('Aucune étape ajoutée.', style: TextStyle(color: Colors.grey)),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _steps.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final step = _steps.removeAt(oldIndex);
              _steps.insert(newIndex, step);
            });
            widget.onChanged(_steps);
          },
          itemBuilder: (context, i) {
            final step = _steps[i];
            return Card(
              key: ValueKey('step_$i'),
              margin: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 14,
                  child: Text('${i + 1}',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(step.text),
                subtitle: step.timerMinutes != null
                    ? Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('${step.timerMinutes} min',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade300, size: 20),
                      onPressed: () => _deleteStep(i),
                    ),
                    Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
                onTap: () => _openStepDialog(existing: step, index: i),
              ),
            );
          },
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openStepDialog(),
          icon: Icon(Icons.add, color: Colors.red),
          label: Text('Ajouter une étape', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red)),
        ),
      ],
    );
  }
}
