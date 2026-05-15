import 'package:get/get.dart';
import 'package:mainchar/screens/announcements/announcements_screen.dart';
import 'package:mainchar/screens/announcements/my_requests_screen.dart';
import 'package:mainchar/screens/announcements/request_announcement_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/votes/voting_arena_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/votes/votes_history_screen.dart';
import '../screens/demo/demo_leaderboard_screen.dart';
import '../screens/demo/demo_profile_screen.dart';
import '../screens/demo/demo_explore_screen.dart';
import '../screens/demo/demo_votes_history_screen.dart';
import 'app_routes.dart';
import '../screens/demo/demo_arena_screen.dart';
import '../screens/legal/terms_screen.dart';
import '../screens/votes/reveal_arena_screen.dart';

class AppPages {
  static const INITIAL = AppRoutes.LOGIN;

  static final routes = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterScreen(),
      transition: Transition.cupertino,
    ),

    GetPage(
      name: AppRoutes.ARENA,
      page: () => const VotingArenaScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.LEADERBOARD,
      page: () => const LeaderboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.EXPLORE,
      page: () => const ExploreScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.ANNOUNCEMENTS,
      page: () => const AnnouncementsScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.ADMIN,
      page: () => const AdminScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.REQUEST_EVENT,
      page: () => const RequestEventScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.VOTES_HISTORY,
      page: () => const VotesHistoryScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.TERMS,
      page: () => const TermsScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.MY_REQUESTS,
      page: () => const MyRequestsScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.REVEAL_ARENA,
      page: () => const RevealArenaScreen(),
      transition: Transition.zoom,
    ),

    // Demo Routes
    GetPage(
      name: AppRoutes.DEMO_EXPLORE,
      page: () => const DemoExploreScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.DEMO_ARENA,
      page: () => DemoArenaScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.DEMO_LEADERBOARD,
      page: () => const DemoLeaderboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.DEMO_PROFILE,
      page: () => const DemoProfileScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.DEMO_VOTES_HISTORY,
      page: () => const DemoVotesHistoryScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
