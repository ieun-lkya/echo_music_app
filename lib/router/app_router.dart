import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/admin_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isGoingToAdmin = state.uri.toString().startsWith('/admin');

    if (isGoingToAdmin) {
      final prefs = await SharedPreferences.getInstance();
      final adminToken = prefs.getString('admin_token');

      if (adminToken == null || adminToken.isEmpty) {
        return '/login';
      }
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
  ],
);
