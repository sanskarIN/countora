# Setup

1. Install Flutter stable 3.38.1+ and platform toolchains required for your target OS.
2. Clone Countora.
3. Generate native runners and Android scheduled-notification setup:

```bash
dart run tool/bootstrap_platforms.dart
```

4. Fetch packages:

```bash
flutter pub get
```

5. Check the environment:

```bash
flutter doctor -v
```

6. Run:

```bash
flutter run
```

Android exact scheduling requests notification and exact-alarm permissions at runtime when notifications are enabled. Platform and store policy requirements should be rechecked before release.
