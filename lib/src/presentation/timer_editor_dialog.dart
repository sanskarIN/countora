import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n.dart';
import '../data/state_codec.dart';
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
  final _stepLabelController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '5');
  final _secondsController = TextEditingController(text: '0');
  final List<IntervalStep> _steps = <IntervalStep>[];

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _stepLabelController.dispose();
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
    if (!_validateDuration(showMessage: true)) return;
    if (_steps.length >= CountoraStateCodec.maxIntervalsPerTimer) {
      _showMessage(
        '${context.l10n.intervalSequence}: '
        '${CountoraStateCodec.maxIntervalsPerTimer} ${context.l10n.steps} max.',
      );
      return;
    }

    final explicitLabel = _stepLabelController.text.trim();
    setState(() {
      _steps.add(
        IntervalStep(
          label: explicitLabel.isEmpty
              ? '${context.l10n.step} ${_steps.length + 1}'
              : explicitLabel,
          durationSeconds: _durationSeconds,
        ),
      );
      _stepLabelController.clear();
    });
  }

  void _moveInterval(int from, int delta) {
    final to = from + delta;
    if (to < 0 || to >= _steps.length) return;
    setState(() {
      final item = _steps.removeAt(from);
      _steps.insert(to, item);
    });
  }

  Future<void> _renameInterval(int index) async {
    final strings = context.l10n;
    final controller = TextEditingController(text: _steps[index].label);
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.renameInterval),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: CountoraStateCodec.maxNameLength,
            decoration: InputDecoration(labelText: strings.label),
            validator: (value) => value == null || value.trim().isEmpty
                ? strings.labelRequired
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(strings.save),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      setState(() {
        final current = _steps[index];
        _steps[index] = IntervalStep(
          label: controller.text.trim(),
          durationSeconds: current.durationSeconds,
        );
      });
    }
    controller.dispose();
  }

  bool _validateDuration({required bool showMessage}) {
    final seconds = _durationSeconds;
    final valid = seconds > 0 &&
        seconds <= CountoraStateCodec.maxIntervalSeconds;
    if (!valid && showMessage) {
      _showMessage(context.l10n.durationRangeError);
    }
    return valid;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    var steps = <IntervalStep>[..._steps];
    if (steps.isEmpty) {
      if (!_validateDuration(showMessage: true)) return;
      steps = <IntervalStep>[
        IntervalStep(
          label: _nameController.text.trim(),
          durationSeconds: _durationSeconds,
        ),
      ];
    }

    Navigator.of(context).pop(
      TimerDraft(
        name: _nameController.text.trim(),
        group: _groupController.text.trim(),
        steps: List<IntervalStep>.unmodifiable(steps),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return AlertDialog(
      title: Text(widget.forPreset ? strings.newPreset : strings.newCountdown),
      content: SizedBox(
        width: 560,
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
                  maxLength: CountoraStateCodec.maxNameLength,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.name,
                    hintText: strings.nameHint,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? strings.nameRequired
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _groupController,
                  maxLength: CountoraStateCodec.maxGroupLength,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.groupOptional,
                    hintText: strings.groupHint,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.duration,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        _hoursController,
                        strings.hours,
                        max: 8760,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField(
                        _minutesController,
                        strings.minutes,
                        max: 59,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField(
                        _secondsController,
                        strings.seconds,
                        max: 59,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stepLabelController,
                  maxLength: CountoraStateCodec.maxNameLength,
                  decoration: InputDecoration(
                    labelText: strings.intervalLabelOptional,
                    hintText: strings.intervalLabelHint,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _steps.length >= CountoraStateCodec.maxIntervalsPerTimer
                          ? null
                          : _addInterval,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(
                    '${strings.addInterval} (${_steps.length}/'
                    '${CountoraStateCodec.maxIntervalsPerTimer})',
                  ),
                ),
                if (_steps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.intervalSequence,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text('${_steps.length} ${strings.steps}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._steps.asMap().entries.map(
                        (entry) => Card.outlined(
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              child: Text('${entry.key + 1}'),
                            ),
                            title: Text(entry.value.label),
                            subtitle: Text(
                              _humanDuration(entry.value.durationSeconds),
                            ),
                            onTap: () =>
                                unawaited(_renameInterval(entry.key)),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: strings.moveIntervalUp,
                                  onPressed: entry.key == 0
                                      ? null
                                      : () => _moveInterval(entry.key, -1),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: strings.moveIntervalDown,
                                  onPressed: entry.key == _steps.length - 1
                                      ? null
                                      : () => _moveInterval(entry.key, 1),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                                IconButton(
                                  tooltip: strings.removeInterval,
                                  onPressed: () {
                                    setState(() => _steps.removeAt(entry.key));
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
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
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.forPreset ? strings.savePreset : strings.startTimer),
        ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required int max,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < 0 || parsed > max) {
          return '0–$max';
        }
        return null;
      },
    );
  }

  String _humanDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final parts = <String>[];
    if (duration.inHours > 0) parts.add('${duration.inHours}h');
    final minutes = duration.inMinutes.remainder(60);
    if (minutes > 0) parts.add('${minutes}m');
    final remainder = duration.inSeconds.remainder(60);
    if (remainder > 0 || parts.isEmpty) parts.add('${remainder}s');
    return parts.join(' ');
  }
}
