import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 920;

    final content = switch (_destinationIndex) {
      1 => _PresetsView(controller: controller),
      2 => _HistoryView(controller: controller),
      _ => _TimersView(controller: controller),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countora'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsPage(controller: controller),
                ),
              );
            },
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
              onDestinationSelected: (value) {
                setState(() => _destinationIndex = value);
              },
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
              onDestinationSelected: (value) {
                setState(() => _destinationIndex = value);
              },
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
          'sequences, and keep everything local to your device.',
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
  const _TimersView({required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    final timers = controller.visibleTimers;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchBar(
                  hintText: 'Search timers, groups, or intervals',
                  leading: const Icon(Icons.search),
                  onChanged: controller.setSearchQuery,
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
                    actions: const <Widget>[SizedBox.shrink()],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (timers.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: Icons.timer_outlined,
              title: 'No countdowns yet',
              message:
                  'Create a timer or start one from a reusable preset.',
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
              onPressed: () => controller.removePreset(preset.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: controller.history.length,
      itemBuilder: (context, index) {
        final item = controller.history[index];
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
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
            ],
          ),
        ),
      ),
    );
  }
}
