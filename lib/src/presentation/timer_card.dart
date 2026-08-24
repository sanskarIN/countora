import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/l10n.dart';
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
    final strings = context.l10n;
    final remaining = controller.remainingFor(timer);
    final total = Duration(seconds: timer.currentStep.durationSeconds);
    final progress = total.inMilliseconds <= 0
        ? 1.0
        : 1 - (remaining.inMilliseconds / total.inMilliseconds);
    final compact = controller.settings.compactCards;
    final statusLabel = switch (timer.status) {
      CountdownStatus.running => strings.running,
      CountdownStatus.paused => strings.paused,
      CountdownStatus.completed => strings.done,
    };

    return Semantics(
      container: true,
      label:
          '${timer.name}, ${formatDuration(remaining)} ${strings.timer.toLowerCase()}, $statusLabel',
      hint: strings.openFocusMode,
      button: true,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => unawaited(_showFocusMode(context)),
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
                              '${strings.step} ${timer.currentStepIndex + 1}/'
                              '${timer.steps.length}: ${timer.currentStep.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_TimerMenuAction>(
                      tooltip: strings.timerOptions,
                      onSelected: (value) =>
                          unawaited(_handleMenuAction(context, value)),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _TimerMenuAction.rename,
                          child: ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(strings.renameMove),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TimerMenuAction.duplicate,
                          child: ListTile(
                            leading: const Icon(Icons.copy_outlined),
                            title: Text(strings.duplicatePaused),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TimerMenuAction.preset,
                          child: ListTile(
                            leading: const Icon(Icons.bookmark_add_outlined),
                            title: Text(strings.saveAsPreset),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TimerMenuAction.restart,
                          child: ListTile(
                            leading: const Icon(Icons.replay),
                            title: Text(strings.restart),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _TimerMenuAction.delete,
                          child: ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: Text(strings.delete),
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
                  semanticsLabel: strings.timerProgress,
                  semanticsValue:
                      '${(progress.clamp(0.0, 1.0) * 100).round()} ${strings.percent}',
                ),
                SizedBox(height: compact ? 8 : 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (timer.status == CountdownStatus.running)
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            unawaited(controller.pause(timer.id)),
                        icon: const Icon(Icons.pause),
                        label: Text(strings.pause),
                      )
                    else if (timer.status == CountdownStatus.paused)
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            unawaited(controller.resume(timer.id)),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(strings.resume),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            unawaited(controller.restart(timer.id)),
                        icon: const Icon(Icons.replay),
                        label: Text(strings.restart),
                      ),
                    OutlinedButton(
                      onPressed: timer.status == CountdownStatus.completed
                          ? null
                          : () => unawaited(
                                controller.addTime(
                                  timer.id,
                                  const Duration(minutes: 1),
                                ),
                              ),
                      child: Text(strings.addOneMinute),
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
    final strings = context.l10n;
    final nameController = TextEditingController(text: timer.name);
    final groupController = TextEditingController(text: timer.group);
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.renameTimer),
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
                  decoration: InputDecoration(labelText: strings.name),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.nameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: groupController,
                  maxLength: 40,
                  decoration: InputDecoration(
                    labelText: strings.groupOptional,
                  ),
                ),
              ],
            ),
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
    final strings = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteTimerTitle),
        content: Text(
          '${strings.delete} “${timer.name}”? ${strings.deleteTimerHistoryNote}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.removeTimer(timer.id);
    }
  }

  Future<void> _showFocusMode(BuildContext context) async {
    final strings = context.l10n;
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
                    child: Text(strings.timerWasRemoved),
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
                                label: '${formatDuration(remaining)} ${strings.timer.toLowerCase()}',
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
                                semanticsLabel: strings.timerProgress,
                                semanticsValue:
                                    '${(progress.clamp(0.0, 1.0) * 100).round()} ${strings.percent}',
                              ),
                              if (active.isSequence) ...[
                                const SizedBox(height: 18),
                                Text(
                                  '${strings.step} ${active.currentStepIndex + 1} '
                                  '${strings.ofLabel} ${active.steps.length}: '
                                  '${active.currentStep.label}',
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
                                      onPressed: () => unawaited(
                                        controller.pause(active.id),
                                      ),
                                      icon: const Icon(Icons.pause),
                                      label: Text(strings.pause),
                                    )
                                  else if (active.status ==
                                      CountdownStatus.paused)
                                    FilledButton.icon(
                                      onPressed: () => unawaited(
                                        controller.resume(active.id),
                                      ),
                                      icon: const Icon(Icons.play_arrow),
                                      label: Text(strings.resume),
                                    )
                                  else
                                    FilledButton.icon(
                                      onPressed: () => unawaited(
                                        controller.restart(active.id),
                                      ),
                                      icon: const Icon(Icons.replay),
                                      label: Text(strings.restart),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: active.status ==
                                            CountdownStatus.completed
                                        ? null
                                        : () => unawaited(
                                              controller.addTime(
                                                active.id,
                                                const Duration(minutes: 1),
                                              ),
                                            ),
                                    icon: const Icon(Icons.add),
                                    label: Text(strings.oneMinute),
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
                        tooltip: strings.exitFocusMode,
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
