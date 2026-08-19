import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_links.dart';
import '../core/app_metadata.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Countora')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.timer_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            AppMetadata.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'A local-first multi-countdown timer for focused work, study, '
            'cooking, routines, and interval workflows.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Version ${AppMetadata.version}+${AppMetadata.buildNumber}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Center(
            child: Chip(
              avatar: Icon(Icons.favorite_outline),
              label: Text(AppMetadata.credit),
            ),
          ),
          const SizedBox(height: 24),
          _LinkTile(
            icon: Icons.code,
            title: 'Source repository',
            subtitle: AppLinks.repository,
            uri: Uri.parse(AppLinks.repository),
          ),
          _LinkTile(
            icon: Icons.person_outline,
            title: 'GitHub profile',
            subtitle: AppLinks.github,
            uri: Uri.parse(AppLinks.github),
          ),
          _LinkTile(
            icon: Icons.coffee_outlined,
            title: 'Buy Me a Coffee',
            subtitle: 'Support Countora development',
            uri: Uri.parse(AppLinks.buyMeACoffee),
          ),
          _LinkTile(
            icon: Icons.mail_outline,
            title: 'Business',
            subtitle: AppLinks.businessEmail,
            uri: Uri(scheme: 'mailto', path: AppLinks.businessEmail),
          ),
          _LinkTile(
            icon: Icons.mail_outline,
            title: 'Business (secondary)',
            subtitle: AppLinks.secondaryBusinessEmail,
            uri: Uri(scheme: 'mailto', path: AppLinks.secondaryBusinessEmail),
          ),
          _LinkTile(
            icon: Icons.support_agent,
            title: 'Support',
            subtitle: AppLinks.supportEmail,
            uri: Uri(scheme: 'mailto', path: AppLinks.supportEmail),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.license_outlined),
            title: Text('License'),
            subtitle: Text(AppMetadata.license),
          ),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Data model'),
            subtitle: Text(AppMetadata.storageModel),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text(
              'Timer data is stored locally. Countora does not require an account.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.accessibility_new),
            title: Text('Accessibility'),
            subtitle: Text(
              'Keyboard navigation, semantic labels, scalable text, reduced '
              'motion, and non-audio countdown cues are supported.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uri,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final launched = await launchUrl(uri);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $subtitle')),
          );
        }
      },
    );
  }
}
