import 'package:flutter_test/flutter_test.dart';

import '../tool/bootstrap_platforms.dart';

void main() {
  test('generates every supported runner without resolving dependencies', () {
    expect(flutterCreateArguments, startsWith(<String>['create', '.']));
    expect(flutterCreateArguments, contains('--project-name=countora'));
    expect(flutterCreateArguments, contains('--org=dev.sanskar'));
    expect(
      flutterCreateArguments,
      contains('--platforms=android,ios,web,windows,macos,linux'),
    );
    expect(flutterCreateArguments, contains('--no-pub'));
  });

  test('does not accidentally enable dependency resolution', () {
    expect(flutterCreateArguments, isNot(contains('--pub')));
    expect(
      flutterCreateArguments.where((argument) => argument.startsWith('--platforms=')),
      hasLength(1),
    );
  });
}
