import 'dart:io';

Future<void> main() async {
  final root = Directory.current.absolute;
  final failures = <String>[];
  final markdownFiles = root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .where((file) => !_isIgnored(file.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final markdownLink = RegExp(r'(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)');
  final markdownImage = RegExp(r'!\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)');

  for (final file in markdownFiles) {
    final content = await file.readAsString();
    final targets = <String>[
      ...markdownLink.allMatches(content).map((match) => match.group(1)!),
      ...markdownImage.allMatches(content).map((match) => match.group(1)!),
    ];

    for (final rawTarget in targets) {
      final target = rawTarget.trim().replaceAll(RegExp(r'^<|>$'), '');
      if (_isExternalOrAnchor(target)) continue;

      final withoutFragment = target.split('#').first.split('?').first;
      if (withoutFragment.isEmpty) continue;

      final decoded = Uri.decodeComponent(withoutFragment);
      final path = decoded.startsWith('/')
          ? '${root.path}${Platform.pathSeparator}${decoded.substring(1)}'
          : '${file.parent.path}${Platform.pathSeparator}$decoded';
      final normalized = File(path).absolute.path;
      if (!File(normalized).existsSync() && !Directory(normalized).existsSync()) {
        failures.add(
          '${_relative(root.path, file.path)} -> $target',
        );
      }
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Broken local Markdown links:');
    for (final failure in failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Checked ${markdownFiles.length} Markdown files; local links are valid.',
  );
}

bool _isIgnored(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.contains('/.dart_tool/') ||
      normalized.contains('/build/') ||
      normalized.contains('/.git/');
}

bool _isExternalOrAnchor(String target) {
  final lower = target.toLowerCase();
  return target.startsWith('#') ||
      lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('mailto:') ||
      lower.startsWith('tel:') ||
      lower.startsWith('data:');
}

String _relative(String root, String path) {
  final normalizedRoot = root.replaceAll('\\', '/');
  final normalizedPath = path.replaceAll('\\', '/');
  if (normalizedPath.startsWith('$normalizedRoot/')) {
    return normalizedPath.substring(normalizedRoot.length + 1);
  }
  return normalizedPath;
}
