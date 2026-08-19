import 'package:countora/src/core/external_link_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final uri = Uri.parse('https://example.com');

  test('returns true when the platform opener succeeds', () async {
    final opened = await openExternalUri(
      uri,
      opener: (value) async {
        expect(value, uri);
        return true;
      },
    );

    expect(opened, isTrue);
  });

  test('returns false when the platform opener declines the URI', () async {
    final opened = await openExternalUri(uri, opener: (_) async => false);

    expect(opened, isFalse);
  });

  test('returns false when the platform opener throws', () async {
    final opened = await openExternalUri(
      uri,
      opener: (_) async => throw StateError('platform unavailable'),
    );

    expect(opened, isFalse);
  });
}
