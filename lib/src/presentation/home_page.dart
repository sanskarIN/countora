import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
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
        _showOnboarding();
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
        title: const Text('Countora'),
        actions: [
          if (_destinationIndex == 0 && controller.timers.isNotEmpty)
            PopupMenuButton<_HomeAction>(
              tooltip: 'Timer actions',
              onSelected: _handleHomeAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _HomeAction.pauseAll,
                  enabled: controller.runningCount > 0,
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.pause_circle_outline),
                    title: Text('Pause all running'),
                  ),
                ),
                PopupMenuItem(
                  value: _HomeAction.resumeAll,
                  enabled: controller.pausedCount > 0,
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.play_circle_outline),
                    title: Text('Resume all paused'),
                  ),
                ),
                PopupMenuItem(
                  value: _HomeAction.removeCompleted,
                  enabled: controller.completedCount > 0,
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.cleaning_services_outlined),
                    title: Text('Remove completed'),
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Settings',
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
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: Text('Timers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bookmark_border),
                  selectedIcon: Icon(Icons.bookmark),
                  label: Text('Presets'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('History'),
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Timers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_border),
                  selectedIcon: Icon(Icons.bookmark),
                  label: 'Presets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
              ],
            ),
      floatingActionButton: _destinationIndex == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(preset: _destinationIndex == 1),
              icon: const Icon(Icons.add),
              label: Text(_destinationIndex == 1 ? 'Preset' : 'Timer'),
            ),
    );

    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              () => _create(preset: _destinationIndex == 1),
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
              () => _create(preset: _destinationIndex == 1),
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(controller: controller),
      ),
    );
  }

  Future<void> _handleHomeAction(_HomeAction action) async {
    switch (action) {
      case _HomeAction.pauseAll:
        await controller.pauseAllRunning();
        break;
      case _HomeAction.resumeAll:
        await controller.resumeAllPaused();
        break;
      case _HomeAction.removeCompleted:
        await controller.removeCompletedTimers();
        break;
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_outlined, size: 44),
        title: const Text('Welcome to Countora'),
        content: const Text(
          'Run multiple countdowns, save reusable presets, build interval '
          'sequences, and keep everything local to your device. On desktop, '
          'use Ctrl/Cmd+N for a new timer and Ctrl/Cmd+F to search.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Get started'),
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
                  hintText: 'Search timers, groups, or intervals',
                  leading: const Icon(Icons.search),
                  trailing: controller.searchQuery.isEmpty
                      ? null
                      : <Widget>[
                          IconButton(
                            tooltip: 'Clear search',
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
                      label: 'Running',
                      count: controller.runningCount,
                      icon: Icons.play_arrow,
                    ),
                    _CountChip(
                      label: 'Paused',
                      count: controller.pausedCount,
                      icon: Icons.pause,
                    ),
                    _CountChip(
                      label: 'Done',
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
                          label: const Text('All'),
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
                        child: const Text('Dismiss'),
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
              title: hasActiveFilter ? 'No matching countdowns' : 'No countdowns yet',
              message: hasActiveFilter
                  ? 'Change the search or group filter to see more timers.'
                  : 'Create a timer or start one from a reusable preset.',
              action: hasActiveFilter
                  ? OutlinedButton.icon(
                      onPressed: () {
                        controller.setSearchQuery('');
                        controller.setGroupFilter('');
                      },
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear filters'),
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
    final presets = [...controller.presets]
      ..sort((a, b) => b.useCount.compareTo(a.useCount));

    if (presets.isEmpty) {
      return const _EmptyState(
        icon: Icons.bookmark_border,
        title: 'No presets yet',
        message: 'Save a timer as a preset or create one directly.',
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
                if (preset.steps.length > 1) '${preset.steps.length} intervals',
                '${preset.useCount} uses',
              ].join(' • '),
            ),
            onTap: () => controller.startPreset(preset.id),
            trailing: IconButton(
              tooltip: 'Delete preset',
              onPressed: () => _confirmDeletePreset(context, preset.id),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete preset?'),
        content: const Text('Existing timers created from it will stay.'),
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
      await controller.removePreset(presetId);
    }
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.history.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'History is empty',
        message: 'Completed timers will appear here.',
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
            tooltip: 'Run again',
            onPressed: () => controller.startFromHistory(item),
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
