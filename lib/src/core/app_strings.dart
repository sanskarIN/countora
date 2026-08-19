import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// English-first application strings with a localization-ready lookup layer.
///
/// UI code should obtain strings through [AppStrings.of] rather than embedding
/// user-facing copy directly. New locales can be added by returning another
/// implementation from the delegate without changing feature widgets.
class AppStrings {
  const AppStrings();

  static const english = AppStrings();

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ?? english;
  }

  String get appName => 'Countora';
  String get settings => 'Settings';
  String get appearance => 'Appearance';
  String get accessibility => 'Accessibility';
  String get systemTheme => 'System';
  String get lightTheme => 'Light';
  String get darkTheme => 'Dark';
  String get compactTimerCards => 'Compact timer cards';
  String get compactTimerCardsDescription =>
      'Use denser layouts on small or busy screens.';
  String get reducedMotion => 'Reduced motion';
  String get reducedMotionDescription =>
      'Prefer minimal movement and transitions.';
  String get notificationsAndCues => 'Notifications & cues';
  String get completionNotifications => 'Completion notifications';
  String get sound => 'Sound';
  String get vibration => 'Vibration';
  String get quietMode => 'Quiet mode';
  String get quietModeDescription =>
      'Keep visual notifications while suppressing sound and vibration.';
  String get privacyAndData => 'Privacy & data';
  String get exportLocalBackup => 'Export local backup';
  String get exportLocalBackupDescription =>
      'Copy a JSON backup to the clipboard.';
  String get backupCopied => 'Backup copied to clipboard.';
  String get importLocalBackup => 'Import local backup';
  String get importLocalBackupDescription => 'Paste a Countora JSON backup.';
  String get clearHistory => 'Clear history';
  String get updatesAndAbout => 'Updates & about';
  String get checkForUpdates => 'Check for updates';
  String get checkForUpdatesDescription => 'Open Countora releases on GitHub.';
  String get couldNotOpenReleases => 'Could not open Countora releases.';
  String get aboutCountora => 'About Countora';
  String get importBackup => 'Import backup';
  String get pasteBackupHint => 'Paste Countora JSON here';
  String get cancel => 'Cancel';
  String get import => 'Import';
  String get backupImported => 'Backup imported.';
  String get invalidBackup => 'That backup is not valid Countora JSON.';
  String get clearHistoryQuestion => 'Clear history?';
  String get clearHistoryDescription =>
      'This removes local completion history. Active timers and presets stay.';
  String get clear => 'Clear';

  String get aboutDescription =>
      'A local-first multi-countdown timer for focused work, study, cooking, '
      'routines, and interval workflows.';
  String get madeBySanskar => 'Made by the Sanskar';
  String get sourceRepository => 'Source repository';
  String get buyMeACoffee => 'Buy Me a Coffee';
  String get supportDevelopment => 'Support Countora development';
  String get business => 'Business';
  String get businessSecondary => 'Business (secondary)';
  String get support => 'Support';
  String get license => 'License';
  String get mitLicense => 'MIT License';
  String get privacy => 'Privacy';
  String get privacyDescription =>
      'Timer data is stored locally. Countora does not require an account.';
  String couldNotOpen(String target) => 'Could not open $target';

  String get timers => 'Timers';
  String get presets => 'Presets';
  String get history => 'History';
  String get timer => 'Timer';
  String get preset => 'Preset';
  String get searchTimers => 'Search timers, groups, or intervals';
  String get all => 'All';
  String get noCountdowns => 'No countdowns yet';
  String get noCountdownsDescription =>
      'Create a timer or start one from a reusable preset.';
  String get noPresets => 'No presets yet';
  String get noPresetsDescription =>
      'Save a timer as a preset or create one directly.';
  String get historyEmpty => 'History is empty';
  String get historyEmptyDescription => 'Completed timers will appear here.';
  String get welcomeTitle => 'Welcome to Countora';
  String get welcomeDescription =>
      'Run multiple countdowns, save reusable presets, build interval '
      'sequences, and keep everything local to your device.';
  String get getStarted => 'Get started';
  String intervalCount(int count) => '$count intervals';
  String useCount(int count) => '$count uses';
  String presetDeleted(String name) => '$name preset deleted.';

  String get timerOptions => 'Timer options';
  String get saveAsPreset => 'Save as preset';
  String get restart => 'Restart';
  String get delete => 'Delete';
  String get undo => 'Undo';
  String timerDeleted(String name) => '$name deleted.';
  String get pause => 'Pause';
  String get resume => 'Resume';
  String get addOneMinute => '+1 min';
  String get timerProgress => 'Timer progress';
  String get exitFocusMode => 'Exit focus mode';
  String timerSemantics(String name, String remaining, String status) =>
      '$name, $remaining remaining, $status';
  String sequenceStep(int current, int total, String label) =>
      'Step $current/$total: $label';

  String get newPreset => 'New preset';
  String get newCountdown => 'New countdown';
  String get name => 'Name';
  String get nameHint => 'Tea, Deep work, Exam…';
  String get nameRequired => 'Name is required.';
  String get groupOptional => 'Group (optional)';
  String get groupHint => 'Study, Kitchen, Work…';
  String get duration => 'Duration';
  String get hours => 'Hours';
  String get minutes => 'Minutes';
  String get seconds => 'Seconds';
  String get nonNegativeNumber => '0+';
  String get stepLabelOptional => 'Step label (optional)';
  String get stepLabelHint => 'Focus, Rest, Simmer…';
  String get addIntervalStep => 'Add as interval step';
  String get choosePositiveDuration => 'Choose a duration above zero.';
  String intervalNumber(int number) => 'Interval $number';
  String get intervalSequence => 'Interval sequence';
  String get removeInterval => 'Remove interval';
  String get savePreset => 'Save preset';
  String get startTimer => 'Start timer';
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(AppStrings.english);
  }

  @override
  bool shouldReload(AppStringsDelegate old) => false;
}
