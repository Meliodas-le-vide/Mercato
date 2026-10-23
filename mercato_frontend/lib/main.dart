import 'package:flutter/material.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.modeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mon Talent',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, child) {
            final brightness = mode == ThemeMode.dark
                ? Brightness.dark
                : mode == ThemeMode.light
                ? Brightness.light
                : MediaQuery.platformBrightnessOf(context);

            final targetTheme = brightness == Brightness.dark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme;

            return AnimatedTheme(
              data: targetTheme,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
