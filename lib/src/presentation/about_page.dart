import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_links.dart';
import '../core/app_metadata.dart';
import '../core/l10n.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.aboutCountora)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.timer_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            strings.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            strings.appTagline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${strings.version} ${AppMetadata.version}+${AppMetadata.buildNumber}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: Chip(
              avatar: const Icon(Icons.favorite_outline),
              label: Text(strings.madeBySanskar),
            ),
          ),
          const SizedBox(height: 24),
          _LinkTile(
            icon: Icons.code,
            title: strings.sourceRepository,
            subtitle: AppLinks.repository,
            uri: Uri.parse(AppLinks.repository),
          ),
          _LinkTile(
            icon: Icons.person_outline,
            title: strings.githubProfile,
            subtitle: AppLinks.github,
            uri: Uri.parse(AppLinks.github),
          ),
          _LinkTile(
            icon: Icons.coffee_outlined,
            title: strings.buyMeACoffee,
            subtitle: strings.supportDevelopment,
            uri: Uri.parse(AppLinks.buyMeACoffee),
          ),
          _LinkTile(
            icon: Icons.mail_outline,
            title: strings.business,
            subtitle: AppLinks.businessEmail,
            uri: Uri(scheme: 'mailto', path: AppLinks.businessEmail),
          ),
          _LinkTile(
            icon: Icons.mail_outline,
            title: strings.businessSecondary,
            subtitle: AppLinks.secondaryBusinessEmail,
            uri: Uri(scheme: 'mailto', path: AppLinks.secondaryBusinessEmail),
          ),
          _LinkTile(
            icon: Icons.support_agent,
            title: strings.support,
            subtitle: AppLinks.supportEmail,
            uri: Uri(scheme: 'mailto', path: AppLinks.supportEmail),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.license_outlined),
            title: Text(strings.license),
            subtitle: Text(strings.mitLicense),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(strings.dataModel),
            subtitle: Text(strings.localFirst),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(strings.privacy),
            subtitle: Text(strings.privacySummary),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: Text(strings.accessibility),
            subtitle: Text(strings.accessibilitySummary),
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
