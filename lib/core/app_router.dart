import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/groups/create_group_screen.dart';
import '../features/groups/group_detail_screen.dart';
import '../features/groups/groups_list_screen.dart';
import '../features/groups/join_group_screen.dart';
import '../features/settlement/settle_up_screen.dart';
import 'supabase.dart';
import 'deep_links.dart';

class _AuthRefreshListenable extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;
  bool _isPasswordRecovery = false;

  bool get isPasswordRecovery => _isPasswordRecovery;

  _AuthRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) {
          _isPasswordRecovery =
              state.event == AuthChangeEvent.passwordRecovery;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable();
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isAuthed =
          ref.read(supabaseClientProvider).auth.currentSession != null;
      final location = state.matchedLocation;
      final onAuthPage = location == '/login' || location == '/signup';

      if (refreshListenable.isPasswordRecovery) {
        return location == '/reset-password' ? null : '/reset-password';
      }
      if (!isAuthed) {
        return onAuthPage ? null : '/login';
      }
      if (location == '/reset-password') {
        return '/';
      }
      if (onAuthPage) {
        return '/';
      }
      final pendingCode = ref.read(pendingJoinCodeProvider);
      if (pendingCode != null && !location.startsWith('/join')) {
        return '/join?code=$pendingCode';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GroupsListScreen(),
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => JoinGroupScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (context, state) =>
            GroupDetailScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id/settle',
        builder: (context, state) =>
            SettleUpScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
    ],
  );
});