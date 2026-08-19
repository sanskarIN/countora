import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export local backup'),
            subtitle: const Text('Copy a JSON backup to the clipboard.'),
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
            subtitle: const Text('Paste a Countora JSON backup.'),
            onTap: () => _importBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear history'),
            onTap: () => _confirmClearHistory(context),
          ),
          const Divider(height: 32),
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
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup'),
        content: TextField(
          controller: textController,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Paste Countora JSON here',
          ),
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

    if (shouldImport != true) {
      textController.dispose();
      return;
    }

    try {
      await controller.importJson(textController.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup imported.')),
      );
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That backup is not valid Countora JSON.')),
      );
    } finally {
      textController.dispose();
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
}
