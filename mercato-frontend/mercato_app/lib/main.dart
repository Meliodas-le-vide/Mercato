import 'package:flutter/material.dart';
import 'package:mercato_app/features/auth/providers/auth_provider.dart';
import 'package:mercato_app/features/player/presentation/dashboard/player_home_screen.dart';
import 'package:mercato_app/features/recruiter/presentation/dashboard/recruiter_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:mercato_app/core/theme/app_theme.dart';
import 'package:mercato_app/features/auth/presentation/login_screen.dart';
import 'package:mercato_app/features/auth/presentation/onboarding_screen.dart';
import 'package:mercato_app/features/auth/presentation/register_screen.dart';
import 'package:mercato_app/features/auth/presentation/role_selection_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
        
          if (auth.isCheckingAuth) {
            return const Scaffold(
              backgroundColor: Color(0xFF0B141B),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)),
              ),
            );
          }

         if (auth.isAuthenticated) {
            if (auth.user?.isRecruiter == true) {
              return const RecruiterHomeScreen(); 
            } else {
              return const PlayerHomeScreen(); 
            }
          }
          return const LoginScreen();
        },
      ),

      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/register') {
          final String selectedRole = (settings.arguments as String?) ?? 'PLAYER';
          return MaterialPageRoute(
            builder: (context) => RegisterScreen(role: selectedRole),
          );
        }
        return null;
      },
    );
  }
}