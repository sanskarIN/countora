import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountdownTimer', () {
    test('computes running remaining time from UTC end instant', () {
      final now = DateTime.utc(2026, 8, 19, 8);
      final timer = CountdownTimer(
        id: '1',
        name: 'Study',
        group: 'Focus',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Study', durationSeconds: 300),
        ],
        currentStepIndex: 0,
        status: CountdownStatus.running,
        remainingWhenPausedSeconds: 300,
        startedAtUtc: now,
        endsAtUtc: now.add(const Duration(minutes: 5)),
      );

      expect(
        timer.remaining(now.add(const Duration(minutes: 2))),
        const Duration(minutes: 3),
      );
    });

    test('never returns negative remaining time', () {
      final now = DateTime.utc(2026, 8, 19, 8);
      final timer = CountdownTimer(
        id: '1',
        name: 'Tea',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Tea', durationSeconds: 60),
        ],
        currentStepIndex: 0,
        status: CountdownStatus.running,
        remainingWhenPausedSeconds: 60,
        endsAtUtc: now.subtract(const Duration(seconds: 1)),
      );

      expect(timer.remaining(now), Duration.zero);
    });

    test('round trips JSON without losing interval sequence', () {
      final timer = CountdownTimer(
        id: 'abc',
        name: 'Pomodoro',
        group: 'Study',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Focus', durationSeconds: 1500),
          IntervalStep(label: 'Break', durationSeconds: 300),
        ],
        currentStepIndex: 1,
        status: CountdownStatus.paused,
        remainingWhenPausedSeconds: 200,
      );

      final decoded = CountdownTimer.fromJson(timer.toJson());

      expect(decoded.id, timer.id);
      expect(decoded.steps.length, 2);
      expect(decoded.currentStep.label, 'Break');
      expect(decoded.remainingWhenPausedSeconds, 200);
    });

    test('defensively supplies a valid interval to malformed state', () {
      final decoded = CountdownTimer.fromJson(<String, Object?>{
        'id': 'bad',
        'name': 'Recovered',
        'steps': <Object?>[],
      });

      expect(decoded.steps, hasLength(1));
      expect(decoded.currentStep.durationSeconds, 60);
    });
  });

  group('CountoraSettings', () {
    test('round trips explicit language preference', () {
      const settings = CountoraSettings(language: CountoraLanguage.hindi);

      final decoded = CountoraSettings.fromJson(settings.toJson());

      expect(decoded.language, CountoraLanguage.hindi);
      expect(decoded.language.locale?.languageCode, 'hi');
    });

    test('defaults missing and unknown language preferences to system', () {
      final missing = CountoraSettings.fromJson(const <String, Object?>{});
      final unknown = CountoraSettings.fromJson(
        const <String, Object?>{'language': 'unsupported'},
      );

      expect(missing.language, CountoraLanguage.system);
      expect(missing.language.locale, isNull);
      expect(unknown.language, CountoraLanguage.system);
      expect(unknown.language.locale, isNull);
    });
  });
}
