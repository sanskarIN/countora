import 'package:flutter/material.dart';

import '../domain/models.dart';

class TimerDraft {
  const TimerDraft({
    required this.name,
    required this.group,
    required this.steps,
  });

  final String name;
  final String group;
  final List<IntervalStep> steps;
}

class TimerEditorDialog extends StatefulWidget {
  const TimerEditorDialog({
    this.forPreset = false,
    super.key,
  });

  final bool forPreset;

  @override
  State<TimerEditorDialog> createState() => _TimerEditorDialogState();
}

class _TimerEditorDialogState extends State<TimerEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _groupController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '5');
  final _secondsController = TextEditingController(text: '0');
  final List<IntervalStep> _steps = <IntervalStep>[];

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  int get _durationSeconds {
    int parse(TextEditingController controller) =>
        int.tryParse(controller.text.trim()) ?? 0;
    return parse(_hoursController) * 3600 +
        parse(_minutesController) * 60 +
        parse(_secondsController);
  }

  void _addInterval() {
    final seconds = _durationSeconds;
    if (seconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a duration above zero.')),
      );
      return;
    }
    setState(() {
      _steps.add(
        IntervalStep(
          label: 'Interval ${_steps.length + 1}',
          durationSeconds: seconds,
        ),
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    var steps = <IntervalStep>[..._steps];
    if (steps.isEmpty) {
      final seconds = _durationSeconds;
      if (seconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a duration above zero.')),
        );
        return;
      }
      steps = <IntervalStep>[
        IntervalStep(
          label: _nameController.text.trim(),
          durationSeconds: seconds,
        ),
      ];
    }

    Navigator.of(context).pop(
      TimerDraft(
        name: _nameController.text.trim(),
        group: _groupController.text.trim(),
        steps: steps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.forPreset ? 'New preset' : 'New countdown'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Tea, Deep work, Exam…',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Name is required.'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _groupController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Group (optional)',
                    hintText: 'Study, Kitchen, Work…',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Duration'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _numberField(_hoursController, 'Hours')),
                    const SizedBox(width: 8),
                    Expanded(child: _numberField(_minutesController, 'Minutes')),
                    const SizedBox(width: 8),
                    Expanded(child: _numberField(_secondsController, 'Seconds')),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addInterval,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add as interval step'),
                ),
                if (_steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Interval sequence',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ..._steps.asMap().entries.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text('${entry.key + 1}'),
                          ),
                          title: Text(entry.value.label),
                          subtitle: Text('${entry.value.durationSeconds}s'),
                          trailing: IconButton(
                            tooltip: 'Remove interval',
                            onPressed: () {
                              setState(() => _steps.removeAt(entry.key));
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.forPreset ? 'Save preset' : 'Start timer'),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < 0) return '0+';
        return null;
      },
    );
  }
}
