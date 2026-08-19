import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n.dart';
import '../data/state_codec.dart';
import '../domain/models.dart';
import 'about_page.dart';
import 'timer_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionTitle(context, strings.appearance),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto),
                label: Text(strings.systemTheme),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode),
                label: Text(strings.lightTheme),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode),
                label: Text(strings.darkTheme),
              ),
            ],
            selected: <ThemeMode>{settings.themeMode},
            onSelectionChanged: (value) => unawaited(
              controller.updateSettings(
                settings.copyWith(themeMode: value.first),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(strings.compactTimerCards),
            subtitle: Text(strings.compactTimerCardsHelp),
            value: settings.compactCards,
            onChanged: (value) => unawaited(
              controller.updateSettings(
                settings.copyWith(compactCards: value),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(strings.reducedMotion),
            subtitle: Text(strings.reducedMotionHelp),
            value: settings.reducedMotion,
            onChanged: (value) => unawaited(
              controller.updateSettings(
                settings.copyWith(reducedMotion: value),
              ),
            ),
          ),
          const Divider(height: 32),
          _sectionTitle(context, strings.notificationsCues),
          SwitchListTile(
            title: Text(strings.completionNotifications),
            subtitle: Text(strings.completionNotificationsHelp),
            value: settings.notificationsEnabled,
            onChanged: (value) => unawaited(
              controller.updateSettings(
                settings.copyWith(notificationsEnabled: value),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(strings.sound),
            value: settings.soundEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) => unawaited(
                      controller.updateSettings(
                        settings.copyWith(soundEnabled: value),
                      ),
                    )
                : null,
          ),
          SwitchListTile(
            title: Text(strings.vibration),
            value: settings.vibrationEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) => unawaited(
                      controller.updateSettings(
                        settings.copyWith(vibrationEnabled: value),
                      ),
                    )
                : null,
          ),
          SwitchListTile(
            title: Text(strings.quietMode),
            subtitle: Text(strings.quietModeHelp),
            value: settings.quietMode,
            onChanged: (value) => unawaited(
              controller.updateSettings(
                settings.copyWith(quietMode: value),
              ),
            ),
          ),
          const Divider(height: 32),
          _sectionTitle(context, strings.privacyData),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(strings.localFirstStorage),
            subtitle: Text(strings.localFirstStorageHelp),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(strings.exportLocalBackup),
            subtitle: Text(strings.exportLocalBackupHelp),
            onTap: () => unawaited(_exportBackup(context)),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(strings.importLocalBackup),
            subtitle: Text(strings.importLocalBackupHelp),
            onTap: () => unawaited(_importBackup(context)),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(strings.clearHistory),
            subtitle: Text(strings.clearHistoryHelp),
            onTap: () => unawaited(_confirmClearHistory(context)),
          ),
          const Divider(height: 32),
          _sectionTitle(context, strings.desktopShortcuts),
          ListTile(
            leading: const Icon(Icons.keyboard_outlined),
            title: Text(strings.newTimerOrPreset),
            trailing: const Text('Ctrl/Cmd + N'),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(strings.searchTimers),
            trailing: const Text('Ctrl/Cmd + F'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(strings.openSettings),
            trailing: const Text('Ctrl/Cmd + ,'),
          ),
          const Divider(height: 32),
          _sectionTitle(context, strings.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.aboutCountora),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AboutPage(),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 32),
          _sectionTitle(context, strings.dangerZone),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              strings.eraseAllData,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: Text(strings.eraseAllDataHelp),
            onTap: () => unawaited(_confirmResetAll(context)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final strings = context.l10n;
    await Clipboard.setData(
      ClipboardData(text: controller.exportJson()),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.backupCopied)),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    final strings = context.l10n;
    final textController = TextEditingController();
    final shouldPreview = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.importBackup),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: textController,
            minLines: 8,
            maxLines: 16,
            decoration: InputDecoration(
              hintText: strings.pasteBackupHint,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.validate),
          ),
        ],
      ),
    );

    if (shouldPreview != true) {
      textController.dispose();
      return;
    }

    final raw = textController.text;
    textController.dispose();

    try {
      final state = const CountoraStateCodec().decode(raw);
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.fact_check_outlined),
          title: Text(strings.backupValid),
          content: Text(
            '${strings.import} ${state.timers.length} ${strings.timers.toLowerCase()}, '
            '${state.presets.length} ${strings.presets.toLowerCase()}, '
            '${state.history.length} ${strings.history.toLowerCase()}?\n\n'
            '${strings.currentDataReplaced}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.import),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await controller.importJson(raw);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.backupImported)),
      );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.backupRejected}: ${error.message}')),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.importFailed)),
      );
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final strings = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.clearHistoryTitle),
        content: Text(strings.clearHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.clear),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearHistory();
    }
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final strings = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(strings.eraseAllDataTitle),
        content: Text(strings.eraseAllDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.eraseAllDataAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.clearAllData();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
