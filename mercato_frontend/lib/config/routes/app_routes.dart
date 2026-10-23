import 'package:flutter/material.dart';
import 'package:mercato_frontend/features/admin/presentation/admin_main_screen.dart';
import 'package:mercato_frontend/features/auth/presentation/onboarding_screen.dart';
import 'package:mercato_frontend/features/events/domain/event_model.dart';
import 'package:mercato_frontend/features/events/presentation/create_event_screen.dart';
import 'package:mercato_frontend/features/events/presentation/event_detail_screen.dart';
import 'package:mercato_frontend/features/events/presentation/event_list_screen.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';
import 'package:mercato_frontend/features/player/presentation/complete_profile_screen.dart';
import 'package:mercato_frontend/features/player/presentation/edit_profile_Screen.dart';
import 'package:mercato_frontend/features/player/presentation/help_screen.dart';
import 'package:mercato_frontend/features/player/presentation/player_Main_screen.dart';
import 'package:mercato_frontend/features/player/presentation/upload_video_screen.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/player/presentation/player_profile_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_edit_profile_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_main_screen.dart';
import 'package:mercato_frontend/features/user/presentation/detail_screen.dart';
import 'package:mercato_frontend/features/user/presentation/home_screen.dart';
import 'package:mercato_frontend/features/user/presentation/main_screen.dart';
import 'package:mercato_frontend/features/user/presentation/profile_edit_screen.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/register_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String upload = '/upload';
  static const String feed = '/feed';
  static const String playerDashboard = '/player-dashboard';
  static const String scoutingSearch = '/scouting-search';
  static const String adminDashboard = '/admin-dashboard';
  static const String editProfile = '/player-edit-profile';
  static const String recruiterEditProfile = '/recruiter-edit-profile';
  static const String completeProfile = '/complete-profile';
  static const String videoplayer = '/video-player';
  static const String profile = '/player-profile';
  static const String help = '/help';
  static const String edit = '/edit';
  static const String detail = '/player-details';
  static const String homeDashboard = '/home-dashboard';
  static const String recruiterUpload = 'recruiter-upload';
  static const String eventsList = '/events';
  static const String eventDetail = '/event-detail';
  static const String createEvent = '/create-event';

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

      // case recruiterUpload:
      //    return MaterialPageRoute(builder: (_) => const RecruiterUploadScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case recruiterEditProfile:
        return MaterialPageRoute(
          builder: (_) => const RecruiterEditProfileScreen(),
        );

      case edit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());

      case detail:
        final player = settings.arguments as PlayerSearchResult;
        return MaterialPageRoute(builder: (_) => DetailScreen(player: player));

      case profile:
        return MaterialPageRoute(builder: (_) => const PlayerProfileScreen());

      case videoplayer:
        final video = settings.arguments as VideoModel;
        return MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(video: video),
        );

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

      case forgotPassword:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen(initialEmail: email),
        );

      case playerDashboard:
        return MaterialPageRoute(builder: (_) => const PlayerMainScreen());

      case scoutingSearch:
        return MaterialPageRoute(builder: (_) => const RecruiterMainScreen());

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminMainScreen());

      case homeDashboard:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case eventsList:
        return MaterialPageRoute(builder: (_) => const EventsListScreen());

      case eventDetail:
        final event = settings.arguments as EventModel;
        return MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        );

      case createEvent:
        return MaterialPageRoute(builder: (_) => const CreateEventScreen());

      case feed:
      default:
        return MaterialPageRoute(builder: (_) => MainScreen());
    }
  }
}
