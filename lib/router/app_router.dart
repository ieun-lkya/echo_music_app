import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/admin_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('echo_token');

    final isGoingToLogin = state.uri.toString() == '/login';

    if ((token == null || token.isEmpty) && !isGoingToLogin) {
      return '/login';
    }

    if (token != null && token.isNotEmpty && isGoingToLogin) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
  ],
);
