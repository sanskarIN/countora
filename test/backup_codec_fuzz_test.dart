import 'dart:math';

import 'package:countora/src/domain/backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deterministic fuzz corpus never escapes with unexpected exceptions', () {
    final random = Random(20260819);
    const alphabet =
        '{}[],:"\\ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    for (var sample = 0; sample < 1000; sample += 1) {
      final length = random.nextInt(512);
      final buffer = StringBuffer();
      for (var index = 0; index < length; index += 1) {
        buffer.write(alphabet[random.nextInt(alphabet.length)]);
      }

      try {
        final state = BackupCodec.decode(buffer.toString());
        expect(BackupCodec.decode(BackupCodec.encode(state)), isNotNull);
      } on FormatException {
        // Invalid untrusted inputs are expected to fail closed.
      } on Object catch (error) {
        fail('Unexpected ${error.runtimeType} for fuzz sample $sample: $error');
      }
    }
  });
}
