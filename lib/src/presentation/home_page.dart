import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/l10n.dart';
import 'settings_page.dart';
import 'timer_card.dart';
import 'timer_controller.dart';
import 'timer_editor_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.controller, super.key});

  final TimerController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _destinationIndex = 0;
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'timer-search');

  TimerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.settings.onboardingSeen && mounted) {
        unawaited(_showOnboarding());
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 920;

    final content = switch (_destinationIndex) {
      1 => _PresetsView(controller: controller),
      2 => _HistoryView(controller: controller),
      _ => _TimersView(
          controller: controller,
          searchFocusNode: _searchFocusNode,
        ),
    };

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          if (_destinationIndex == 0 && controller.timers.isNotEmpty)
            PopupMenuButton<_HomeAction>(
              tooltip: strings.timerActions,
              onSelected: (action) => unawaited(_handleHomeAction(action)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _HomeAction.pauseAll,
                  enabled: controller.runningCount > 0,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pause_circle_outline),
                    title: Text(strings.pauseAllRunning),
                  ),
                ),
                PopupMenuItem(
                  value: _HomeAction.resumeAll,
                  enabled: controller.pausedCount > 0,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(strings.resumeAllPaused),
                  ),
                ),
                PopupMenuItem(
                  value: _HomeAction.removeCompleted,
                  enabled: controller.completedCount > 0,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: Text(strings.removeCompleted),
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: strings.settings,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _destinationIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.timer_outlined),
                  selectedIcon: const Icon(Icons.timer),
                  label: Text(strings.timers),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.bookmark_border),
                  selectedIcon: const Icon(Icons.bookmark),
                  label: Text(strings.presets),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.history),
                  label: Text(strings.history),
                ),
              ],
            ),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _destinationIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.timer_outlined),
                  selectedIcon: const Icon(Icons.timer),
                  label: strings.timers,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_border),
                  selectedIcon: const Icon(Icons.bookmark),
                  label: strings.presets,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history),
                  label: strings.history,
                ),
              ],
            ),
      floatingActionButton: _destinationIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  unawaited(_create(preset: _destinationIndex == 1)),
              icon: const Icon(Icons.add),
              label: Text(
                _destinationIndex == 1 ? strings.preset : strings.timer,
              ),
            ),
    );

    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              () => unawaited(_create(preset: _destinationIndex == 1)),
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
              () => unawaited(_create(preset: _destinationIndex == 1)),
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              _focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
              _focusSearch,
          const SingleActivator(LogicalKeyboardKey.comma, control: true):
              _openSettings,
          const SingleActivator(LogicalKeyboardKey.comma, meta: true):
              _openSettings,
        },
        child: scaffold,
      ),
    );
  }

  void _selectDestination(int value) {
    setState(() => _destinationIndex = value);
  }

  void _focusSearch() {
    if (_destinationIndex != 0) {
      setState(() => _destinationIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    } else {
      _searchFocusNode.requestFocus();
    }
  }

  void _openSettings() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsPage(controller: controller),
        ),
      ),
    );
  }

  Future<void> _handleHomeAction(_HomeAction action) async {
    switch (action) {
      case _HomeAction.pauseAll:
        await controller.pauseAllRunning();
      case _HomeAction.resumeAll:
        await controller.resumeAllPaused();
      case _HomeAction.removeCompleted:
        await controller.removeCompletedTimers();
    }
  }

  Future<void> _create({required bool preset}) async {
    final draft = await showDialog<TimerDraft>(
      context: context,
      builder: (_) => TimerEditorDialog(forPreset: preset),
    );
    if (draft == null) return;

    if (preset) {
      await controller.addPreset(
        name: draft.name,
        group: draft.group,
        steps: draft.steps,
      );
    } else {
      await controller.addTimer(
        name: draft.name,
        group: draft.group,
        steps: draft.steps,
      );
    }
  }

  Future<void> _showOnboarding() async {
    final strings = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_outlined, size: 44),
        title: Text(strings.welcomeTitle),
        content: Text('${strings.welcomeBody} ${strings.newTimerShortcutHint}'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.getStarted),
          ),
        ],
      ),
    );
    await controller.markOnboardingSeen();
  }
}

class _TimersView extends StatelessWidget {
  const _TimersView({
    required this.controller,
    required this.searchFocusNode,
  });

  final TimerController controller;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final timers = controller.visibleTimers;
    final hasActiveFilter = controller.searchQuery.trim().isNotEmpty ||
        controller.groupFilter.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchBar(
                  focusNode: searchFocusNode,
                  hintText: strings.searchTimersHint,
                  leading: const Icon(Icons.search),
                  trailing: controller.searchQuery.isEmpty
                      ? null
                      : <Widget>[
                          IconButton(
                            tooltip: strings.clearSearch,
                            onPressed: () => controller.setSearchQuery(''),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                  onChanged: controller.setSearchQuery,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CountChip(
                      label: strings.running,
                      count: controller.runningCount,
                      icon: Icons.play_arrow,
                    ),
                    _CountChip(
                      label: strings.paused,
                      count: controller.pausedCount,
                      icon: Icons.pause,
                    ),
                    _CountChip(
                      label: strings.done,
                      count: controller.completedCount,
                      icon: Icons.check,
                    ),
                  ],
                ),
                if (controller.groups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(strings.all),
                          selected: controller.groupFilter.isEmpty,
                          onSelected: (_) => controller.setGroupFilter(''),
                        ),
                        const SizedBox(width: 8),
                        ...controller.groups.expand(
                          (group) => [
                            ChoiceChip(
                              label: Text(group),
                              selected: controller.groupFilter == group,
                              onSelected: (_) =>
                                  controller.setGroupFilter(group),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (controller.lastError != null) ...[
                  const SizedBox(height: 12),
                  MaterialBanner(
                    content: Text(controller.lastError!),
                    actions: <Widget>[
                      TextButton(
                        onPressed: controller.clearError,
                        child: Text(strings.dismiss),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (timers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: hasActiveFilter
                  ? Icons.search_off_outlined
                  : Icons.timer_outlined,
              title: hasActiveFilter
                  ? strings.noMatchingCountdowns
                  : strings.noCountdownsYet,
              message: hasActiveFilter
                  ? strings.noMatchingCountdownsMessage
                  : strings.noCountdownsMessage,
              action: hasActiveFilter
                  ? OutlinedButton.icon(
                      onPressed: () {
                        controller.setSearchQuery('');
                        controller.setGroupFilter('');
                      },
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: Text(strings.clearFilters),
                    )
                  : null,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 1100
                    ? 3
                    : constraints.crossAxisExtent >= 650
                        ? 2
                        : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent:
                        controller.settings.compactCards ? 230 : 290,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => TimerCard(
                      timer: timers[index],
                      controller: controller,
                    ),
                    childCount: timers.length,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PresetsView extends StatelessWidget {
  const _PresetsView({required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final presets = [...controller.presets]
      ..sort((a, b) => b.useCount.compareTo(a.useCount));

    if (presets.isEmpty) {
      return _EmptyState(
        icon: Icons.bookmark_border,
        title: strings.noPresetsYet,
        message: strings.noPresetsMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: presets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final preset = presets[index];
        final duration = Duration(
          seconds: preset.steps.fold<int>(
            0,
            (sum, item) => sum + item.durationSeconds,
          ),
        );
        return Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text(preset.name),
            subtitle: Text(
              [
                if (preset.group.isNotEmpty) preset.group,
                humanizeDuration(duration),
                if (preset.steps.length > 1)
                  '${preset.steps.length} ${strings.intervals}',
                '${preset.useCount} ${strings.uses}',
              ].join(' • '),
            ),
            onTap: () => unawaited(controller.startPreset(preset.id)),
            trailing: IconButton(
              tooltip: strings.deletePreset,
              onPressed: () =>
                  unawaited(_confirmDeletePreset(context, preset.id)),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePreset(
    BuildContext context,
    String presetId,
  ) async {
    final strings = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deletePresetTitle),
        content: Text(strings.deletePresetMessage),
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
      await controller.removePreset(presetId);
    }
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    if (controller.history.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: strings.historyEmpty,
        message: strings.historyEmptyMessage,
      );
    }

    final history = [...controller.history]
      ..sort((a, b) => b.completedAtUtc.compareTo(a.completedAtUtc));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(item.name),
          subtitle: Text(
            [
              if (item.group.isNotEmpty) item.group,
              humanizeDuration(
                Duration(seconds: item.totalDurationSeconds),
              ),
              item.completedAtUtc.toLocal().toString(),
            ].join(' • '),
          ),
          trailing: IconButton(
            tooltip: strings.runAgain,
            onPressed: () => unawaited(controller.startFromHistory(item)),
            icon: const Icon(Icons.replay),
          ),
        );
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label $count'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _HomeAction { pauseAll, resumeAll, removeCompleted }
