import 'package:flutter/material.dart';
import 'package:mercato_frontend/features/auth/presentation/onboarding_screen.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';
import 'package:mercato_frontend/features/player/presentation/complete_profile_screen.dart';
import 'package:mercato_frontend/features/player/presentation/edit_profile_Screen.dart';
import 'package:mercato_frontend/features/player/presentation/help_screen.dart';
import 'package:mercato_frontend/features/player/presentation/player_Main_screen.dart';
import 'package:mercato_frontend/features/player/presentation/upload_video_screen.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/player/presentation/player_profile_screen.dart';
import 'package:mercato_frontend/features/user/presentation/detail_screen.dart' hide PlayerProfileScreen;
import 'package:mercato_frontend/features/user/presentation/main_screen.dart';
import 'package:mercato_frontend/features/user/presentation/profile_edit_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

class AppRoutes {


  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String upload = '/upload';
  static const String feed = '/feed';
  static const String playerDashboard = '/player-dashboard';
  static const String scoutingSearch = '/scouting-search';
  static const String editProfile = '/player-edit-profile';
  static const String completeProfile = '/complete-profile';
  static const String videoplayer = '/video-player';
  static const String profile = '/player-profile';
  static const String help = '/help'; 
  static const String edit = '/edit';
  static const String detail = '/player-details';
  

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case onboarding: 
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());  

      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      
      case upload:
        return MaterialPageRoute(builder: (_) => const PlayerUploadScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case edit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());  

      case detail: 
        final player = settings.arguments as PlayerSearchResult;
        return MaterialPageRoute(builder: (_) => DetailScreen(player: player));
        
      case profile:
        return MaterialPageRoute(builder: (_) => const PlayerProfileScreen());  

      case videoplayer:
        final video = settings.arguments as VideoModel;
        return MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video));

      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());  

      case completeProfile:
        return MaterialPageRoute(builder: (_) => const CompleteProfileScreen());  

      case login:
        final selectedRole = settings.arguments as String? ?? 'USER';
        return MaterialPageRoute(
          builder: (_) => LoginScreen(selectedRole: selectedRole),
        );

      case register:
        final selectedRole = settings.arguments as String? ?? 'USER';
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(selectedRole: selectedRole),
        );

      case playerDashboard:
        return MaterialPageRoute(
          builder: (_) => const PlayerMainScreen(),
        );

      case scoutingSearch:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Espace Recruteur')),
            body: const Center(child: Text('Moteur de recherche Scouting')),
          ),
        );

      case feed:
      default:
        return MaterialPageRoute(
          builder: (_) => MainScreen()
        );
    }
  }
}