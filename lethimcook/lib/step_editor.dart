import 'package:flutter/material.dart';
import 'recipe_step.dart';
import 'app_theme.dart';

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

  void _openDialog({RecipeStep? existing, int? index}) {
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    final timerCtrl = TextEditingController(
      text: existing?.timerMinutes != null
          ? existing!.timerMinutes.toString()
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Ajouter une étape' : 'Modifier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description de l\'étape'),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timerCtrl,
              decoration: const InputDecoration(
                labelText: 'Timer (minutes, optionnel)',
                hintText: 'ex: 20',
                prefixIcon:
                    Icon(Icons.timer_outlined, color: kTextSecondary),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final text = textCtrl.text.trim();
              if (text.isEmpty) return;
              final timer = int.tryParse(timerCtrl.text.trim());
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
        const Text('Étapes',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary)),
        const SizedBox(height: 10),
        if (_steps.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Aucune étape ajoutée.',
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
            return Container(
              key: ValueKey('step_$i'),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: kPrimary, borderRadius: BorderRadius.circular(7)),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.text,
                            style: const TextStyle(
                                fontSize: 13, color: kTextPrimary)),
                        if (step.timerMinutes != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 12, color: kTextSecondary),
                              const SizedBox(width: 3),
                              Text('${step.timerMinutes} min',
                                  style: const TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: kTextSecondary, size: 18),
                    onPressed: () => _openDialog(existing: step, index: i),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade300, size: 18),
                    onPressed: () {
                      setState(() => _steps.removeAt(i));
                      widget.onChanged(_steps);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  const Icon(Icons.drag_handle,
                      color: kTextSecondary, size: 18),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter une étape'),
        ),
      ],
    );
  }
}
