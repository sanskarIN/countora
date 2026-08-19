import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/state_codec.dart';
import '../domain/models.dart';
import 'about_page.dart';
import 'timer_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionTitle(context, 'Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Dark'),
              ),
            ],
            selected: <ThemeMode>{settings.themeMode},
            onSelectionChanged: (value) {
              controller.updateSettings(
                settings.copyWith(themeMode: value.first),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Compact timer cards'),
            subtitle: const Text('Use denser layouts on small or busy screens.'),
            value: settings.compactCards,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(compactCards: value),
            ),
          ),
          SwitchListTile(
            title: const Text('Reduced motion'),
            subtitle: const Text('Prefer minimal movement and transitions.'),
            value: settings.reducedMotion,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(reducedMotion: value),
            ),
          ),
          const Divider(height: 32),
          _sectionTitle(context, 'Notifications & cues'),
          SwitchListTile(
            title: const Text('Completion notifications'),
            subtitle: const Text(
              'Use platform notifications so countdowns can finish while '
              'Countora is not in the foreground.',
            ),
            value: settings.notificationsEnabled,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(notificationsEnabled: value),
            ),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: settings.soundEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) => controller.updateSettings(
                      settings.copyWith(soundEnabled: value),
                    )
                : null,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: settings.vibrationEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) => controller.updateSettings(
                      settings.copyWith(vibrationEnabled: value),
                    )
                : null,
          ),
          SwitchListTile(
            title: const Text('Quiet mode'),
            subtitle: const Text(
              'Keep visual notifications while suppressing sound and vibration.',
            ),
            value: settings.quietMode,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(quietMode: value),
            ),
          ),
          const Divider(height: 32),
          _sectionTitle(context, 'Privacy & data'),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Local-first storage'),
            subtitle: Text(
              'Timers, presets, history, and preferences stay on this device '
              'unless you explicitly copy a backup.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export local backup'),
            subtitle: const Text('Copy a versioned JSON backup to the clipboard.'),
            onTap: () async {
              await Clipboard.setData(
                ClipboardData(text: controller.exportJson()),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup copied to clipboard.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import local backup'),
            subtitle: const Text(
              'Validate and preview a Countora JSON backup before replacing data.',
            ),
            onTap: () => _importBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear history'),
            subtitle: const Text('Keep active timers and presets.'),
            onTap: () => _confirmClearHistory(context),
          ),
          const Divider(height: 32),
          _sectionTitle(context, 'Desktop shortcuts'),
          const ListTile(
            leading: Icon(Icons.keyboard_outlined),
            title: Text('New timer or preset'),
            trailing: Text('Ctrl/Cmd + N'),
          ),
          const ListTile(
            leading: Icon(Icons.search),
            title: Text('Search timers'),
            trailing: Text('Ctrl/Cmd + F'),
          ),
          const ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Open settings'),
            trailing: Text('Ctrl/Cmd + ,'),
          ),
          const Divider(height: 32),
          _sectionTitle(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Countora'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutPage(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          _sectionTitle(context, 'Danger zone'),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Erase all local Countora data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Deletes timers, presets, history, and settings from this device.',
            ),
            onTap: () => _confirmResetAll(context),
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

  Future<void> _importBackup(BuildContext context) async {
    final textController = TextEditingController();
    final shouldPreview = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: textController,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              hintText: 'Paste Countora JSON here',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Validate'),
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
          title: const Text('Backup is valid'),
          content: Text(
            'Import ${state.timers.length} timers, ${state.presets.length} '
            'presets, and ${state.history.length} history entries?\n\n'
            'Your current local Countora data will be replaced.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await controller.importJson(raw);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup imported.')),
      );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup rejected: ${error.message}')),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import failed. Your current data was not intentionally cleared.'),
        ),
      );
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes local completion history. Active timers and presets stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearHistory();
    }
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Erase all local data?'),
        content: const Text(
          'This cannot be undone unless you exported a backup first. Active '
          'notifications will also be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase all data'),
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
