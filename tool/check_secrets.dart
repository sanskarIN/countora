import 'dart:io';

void main() {
  final root = Directory.current.absolute;
  final findings = <String>[];
  final patterns = <String, RegExp>{
    'private key': RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'GitHub token': RegExp(r'\bgh[pousr]_[A-Za-z0-9]{30,}\b'),
    'GitHub fine-grained token': RegExp(r'\bgithub_pat_[A-Za-z0-9_]{20,}\b'),
    'AWS access key': RegExp(r'\bAKIA[0-9A-Z]{16}\b'),
    'Google API key': RegExp(r'\bAIza[0-9A-Za-z_-]{35}\b'),
  };

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || _isIgnored(entity.path)) continue;
    if (!_looksTextual(entity.path)) continue;

    String content;
    try {
      content = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    } on FormatException {
      continue;
    }

    for (final entry in patterns.entries) {
      if (entry.value.hasMatch(content)) {
        findings.add('${_relative(root.path, entity.path)}: ${entry.key} pattern');
      }
    }
  }

  if (findings.isNotEmpty) {
    stderr.writeln('Potential committed secrets detected:');
    for (final finding in findings) {
      stderr.writeln('  - $finding');
    }
    stderr.writeln('Review findings; never suppress a real credential.');
    exitCode = 1;
    return;
  }

  stdout.writeln('No supported committed-secret patterns were detected.');
}

bool _isIgnored(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.contains('/.git/') ||
      normalized.contains('/.dart_tool/') ||
      normalized.contains('/build/') ||
      normalized.endsWith('/tool/check_secrets.dart');
}

bool _looksTextual(String path) {
  final normalized = path.toLowerCase();
  const extensions = <String>[
    '.dart',
    '.md',
    '.yaml',
    '.yml',
    '.json',
    '.arb',
    '.xml',
    '.gradle',
    '.kts',
    '.properties',
    '.txt',
    '.example',
  ];
  return extensions.any(normalized.endsWith) ||
      normalized.endsWith('/license') ||
      normalized.endsWith('/.gitignore') ||
      normalized.endsWith('/.gitattributes') ||
      normalized.endsWith('/.editorconfig');
}

String _relative(String root, String path) {
  final normalizedRoot = root.replaceAll('\\', '/');
  final normalizedPath = path.replaceAll('\\', '/');
  if (normalizedPath.startsWith('$normalizedRoot/')) {
    return normalizedPath.substring(normalizedRoot.length + 1);
  }
  return normalizedPath;
}
