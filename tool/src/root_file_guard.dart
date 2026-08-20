import 'dart:io';

typedef RootFileSnapshots = Map<String, List<int>?>;

RootFileSnapshots snapshotRootFiles(
  Directory root,
  Iterable<String> relativePaths,
) {
  final snapshots = <String, List<int>?>{};
  for (final path in relativePaths) {
    final file = _fileAt(root, path);
    snapshots[path] = file.existsSync() ? file.readAsBytesSync() : null;
  }
  return snapshots;
}

void restoreRootFiles(Directory root, RootFileSnapshots snapshots) {
  for (final entry in snapshots.entries) {
    final file = _fileAt(root, entry.key);
    final bytes = entry.value;
    if (bytes == null) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      continue;
    }

    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes, flush: true);
  }
}

File _fileAt(Directory root, String relativePath) {
  final segments = relativePath.split(RegExp(r'[\\/]'));
  if (relativePath.isEmpty ||
      File(relativePath).isAbsolute ||
      segments.contains('..')) {
    throw ArgumentError.value(
      relativePath,
      'relativePath',
      'Expected a safe repository-relative file path.',
    );
  }
  return File('${root.path}${Platform.pathSeparator}$relativePath');
}
