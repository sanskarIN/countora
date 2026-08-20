import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/src/root_file_guard.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('countora-root-guard-');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('restores existing root files and removes generated absent files', () {
    final pubspec = File('${tempDirectory.path}${Platform.pathSeparator}pubspec.yaml')
      ..writeAsStringSync('name: countora\n');
    final lockfile = File('${tempDirectory.path}${Platform.pathSeparator}pubspec.lock');

    final snapshots = snapshotRootFiles(
      tempDirectory,
      const <String>['pubspec.yaml', 'pubspec.lock'],
    );

    pubspec.writeAsStringSync('name: overwritten\n');
    lockfile.writeAsStringSync('generated: true\n');

    restoreRootFiles(tempDirectory, snapshots);

    expect(pubspec.readAsStringSync(), 'name: countora\n');
    expect(lockfile.existsSync(), isFalse);
  });

  test('restores exact bytes instead of normalizing text content', () {
    final readme = File('${tempDirectory.path}${Platform.pathSeparator}README.md');
    final originalBytes = <int>[0x43, 0x6f, 0x75, 0x6e, 0x74, 0x6f, 0x72, 0x61, 0x0d, 0x0a];
    readme.writeAsBytesSync(originalBytes);

    final snapshots = snapshotRootFiles(
      tempDirectory,
      const <String>['README.md'],
    );
    readme.writeAsStringSync('changed\n');

    restoreRootFiles(tempDirectory, snapshots);

    expect(readme.readAsBytesSync(), originalBytes);
  });

  test('rejects traversal and absolute paths', () {
    expect(
      () => snapshotRootFiles(tempDirectory, const <String>['../outside']),
      throwsArgumentError,
    );
    expect(
      () => snapshotRootFiles(tempDirectory, const <String>['/outside']),
      throwsArgumentError,
    );
  });
}
