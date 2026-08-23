import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'core/app_theme.dart';
import 'domain/models.dart';
import 'presentation/home_page.dart';
import 'presentation/timer_controller.dart';

class CountoraApp extends StatefulWidget {
  const CountoraApp({required this.controller, super.key});

  final TimerController controller;

  @override
  State<CountoraApp> createState() => _CountoraAppState();
}

class _CountoraAppState extends State<CountoraApp>
    with WidgetsBindingObserver {
  TimerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.reconcile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: controller.settings.language.locale,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.settings.themeMode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                disableAnimations:
                    controller.settings.reducedMotion || media.disableAnimations,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: HomePage(controller: controller),
        );
      },
    );
  }
}
