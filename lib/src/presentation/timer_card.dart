import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../domain/models.dart';
import 'timer_controller.dart';

class TimerCard extends StatelessWidget {
  const TimerCard({
    required this.timer,
    required this.controller,
    super.key,
  });

  final CountdownTimer timer;
  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    final remaining = controller.remainingFor(timer);
    final total = Duration(seconds: timer.currentStep.durationSeconds);
    final progress = total.inMilliseconds <= 0
        ? 1.0
        : 1 - (remaining.inMilliseconds / total.inMilliseconds);
    final compact = controller.settings.compactCards;

    return Semantics(
      container: true,
      label:
          '${timer.name}, ${formatDuration(remaining)} remaining, ${timer.status.name}',
      hint: 'Open full-screen focus mode',
      button: true,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showFocusMode(context),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timer.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (timer.group.isNotEmpty)
                            Text(
                              timer.group,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (timer.isSequence)
                            Text(
                              'Step ${timer.currentStepIndex + 1}/${timer.steps.length}: '
                              '${timer.currentStep.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_TimerMenuAction>(
                      tooltip: 'Timer options',
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _TimerMenuAction.rename,
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Rename / move'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TimerMenuAction.duplicate,
                          child: ListTile(
                            leading: Icon(Icons.copy_outlined),
                            title: Text('Duplicate paused'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TimerMenuAction.preset,
                          child: ListTile(
                            leading: Icon(Icons.bookmark_add_outlined),
                            title: Text('Save as preset'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TimerMenuAction.restart,
                          child: ListTile(
                            leading: Icon(Icons.replay),
                            title: Text('Restart'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: _TimerMenuAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 16),
                Text(
                  formatDuration(remaining),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  semanticsLabel: 'Timer progress',
                  semanticsValue:
                      '${(progress.clamp(0.0, 1.0) * 100).round()} percent',
                ),
                SizedBox(height: compact ? 8 : 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (timer.status == CountdownStatus.running)
                      FilledButton.tonalIcon(
                        onPressed: () => controller.pause(timer.id),
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      )
                    else if (timer.status == CountdownStatus.paused)
                      FilledButton.tonalIcon(
                        onPressed: () => controller.resume(timer.id),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: () => controller.restart(timer.id),
                        icon: const Icon(Icons.replay),
                        label: const Text('Restart'),
                      ),
                    OutlinedButton(
                      onPressed: timer.status == CountdownStatus.completed
                          ? null
                          : () => controller.addTime(
                                timer.id,
                                const Duration(minutes: 1),
                              ),
                      child: const Text('+1 min'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _TimerMenuAction action,
  ) async {
    switch (action) {
      case _TimerMenuAction.rename:
        await _renameTimer(context);
      case _TimerMenuAction.duplicate:
        await controller.duplicateTimer(timer.id);
      case _TimerMenuAction.preset:
        await controller.saveTimerAsPreset(timer.id);
      case _TimerMenuAction.restart:
        await controller.restart(timer.id);
      case _TimerMenuAction.delete:
        await _confirmDelete(context);
    }
  }

  Future<void> _renameTimer(BuildContext context) async {
    final nameController = TextEditingController(text: timer.name);
    final groupController = TextEditingController(text: timer.group);
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename timer'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: groupController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Group (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await controller.updateTimerDetails(
        timerId: timer.id,
        name: nameController.text,
        group: groupController.text,
      );
    }
    nameController.dispose();
    groupController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete timer?'),
        content: Text('Delete “${timer.name}”? This does not clear history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removeTimer(timer.id);
    }
  }

  Future<void> _showFocusMode(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            CountdownTimer? visible;
            for (final item in controller.timers) {
              if (item.id == timer.id) {
                visible = item;
                break;
              }
            }
            if (visible == null) {
              return Dialog.fullscreen(
                child: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Timer was removed'),
                  ),
                ),
              );
            }

            final active = visible;
            final remaining = controller.remainingFor(active);
            final total = Duration(seconds: active.currentStep.durationSeconds);
            final progress = total.inMilliseconds <= 0
                ? 1.0
                : 1 - (remaining.inMilliseconds / total.inMilliseconds);

            return Dialog.fullscreen(
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                active.name,
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              if (active.group.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(active.group),
                              ],
                              const SizedBox(height: 28),
                              Semantics(
                                liveRegion: true,
                                label: '${formatDuration(remaining)} remaining',
                                child: Text(
                                  formatDuration(remaining),
                                  textAlign: TextAlign.center,
                                  style:
                                      Theme.of(context).textTheme.displayLarge,
                                ),
                              ),
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0).toDouble(),
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              if (active.isSequence) ...[
                                const SizedBox(height: 18),
                                Text(
                                  'Step ${active.currentStepIndex + 1} of '
                                  '${active.steps.length}: ${active.currentStep.label}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                              const SizedBox(height: 28),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  if (active.status == CountdownStatus.running)
                                    FilledButton.icon(
                                      onPressed: () =>
                                          controller.pause(active.id),
                                      icon: const Icon(Icons.pause),
                                      label: const Text('Pause'),
                                    )
                                  else if (active.status ==
                                      CountdownStatus.paused)
                                    FilledButton.icon(
                                      onPressed: () =>
                                          controller.resume(active.id),
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Resume'),
                                    )
                                  else
                                    FilledButton.icon(
                                      onPressed: () =>
                                          controller.restart(active.id),
                                      icon: const Icon(Icons.replay),
                                      label: const Text('Restart'),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: active.status ==
                                            CountdownStatus.completed
                                        ? null
                                        : () => controller.addTime(
                                              active.id,
                                              const Duration(minutes: 1),
                                            ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('1 minute'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filledTonal(
                        tooltip: 'Exit focus mode',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_fullscreen),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _TimerMenuAction { rename, duplicate, preset, restart, delete }
