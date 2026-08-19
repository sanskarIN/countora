import 'package:flutter/material.dart';

import 'core/app_strings.dart';
import 'core/app_theme.dart';
import 'presentation/home_page.dart';
import 'presentation/timer_controller.dart';

class CountoraApp extends StatelessWidget {
  const CountoraApp({required this.controller, super.key});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppStrings.of(context).appName,
          localizationsDelegates: const [AppStringsDelegate()],
          supportedLocales: const <Locale>[Locale('en')],
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
