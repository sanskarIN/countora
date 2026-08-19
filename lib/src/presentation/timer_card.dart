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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (timer.group.isNotEmpty)
                            Text(
                              timer.group,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (timer.isSequence)
                            Text(
                              'Step ${timer.currentStepIndex + 1}/${timer.steps.length}: '
                              '${timer.currentStep.label}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Timer options',
                      onSelected: (value) async {
                        if (value == 'preset') {
                          await controller.saveTimerAsPreset(timer.id);
                        } else if (value == 'restart') {
                          await controller.restart(timer.id);
                        } else if (value == 'delete') {
                          await controller.removeTimer(timer.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'preset',
                          child: Text('Save as preset'),
                        ),
                        PopupMenuItem(
                          value: 'restart',
                          child: Text('Restart'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
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

  Future<void> _showFocusMode(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            var visible = timer;
            for (final item in controller.timers) {
              if (item.id == timer.id) {
                visible = item;
                break;
              }
            }
            final remaining = controller.remainingFor(visible);
            return Dialog.fullscreen(
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              visible.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              formatDuration(remaining),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            if (visible.isSequence) ...[
                              const SizedBox(height: 16),
                              Text(visible.currentStep.label),
                            ],
                          ],
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
