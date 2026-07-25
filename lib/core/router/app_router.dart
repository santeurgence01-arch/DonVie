import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/widgets/app_shell.dart';
import 'package:health_emergency/features/auth/application/auth_providers.dart';
import 'package:health_emergency/features/auth/presentation/login_screen.dart';
import 'package:health_emergency/features/dashboard/presentation/dashboard_screen.dart';
import 'package:health_emergency/features/donors/presentation/donor_detail_screen.dart';
import 'package:health_emergency/features/donors/presentation/donor_form_screen.dart';
import 'package:health_emergency/features/donors/presentation/donors_list_screen.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:health_emergency/features/onboarding/presentation/onboarding_screen.dart';
import 'package:health_emergency/features/requests/presentation/request_tracking_screen.dart';
import 'package:health_emergency/features/requests/presentation/request_wizard_screen.dart';
import 'package:health_emergency/features/requests/presentation/requests_history_screen.dart';
import 'package:health_emergency/features/requests/presentation/requests_list_screen.dart';
import 'package:health_emergency/features/settings/presentation/profile_screen.dart';
import 'package:health_emergency/features/stock/presentation/stock_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final structureState = ref.watch(structureDocProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/donors/new',
        builder: (context, state) => const DonorFormScreen(),
      ),
      GoRoute(
        path: '/donors/:id',
        builder: (context, state) =>
            DonorDetailScreen(donorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/requests/new',
        builder: (context, state) => const RequestWizardScreen(),
      ),
      GoRoute(
        path: '/requests/history',
        builder: (context, state) => const RequestsHistoryScreen(),
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) =>
            RequestTrackingScreen(demandeId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/donors',
                builder: (context, state) => const DonorsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stock',
                builder: (context, state) => const StockScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) => const RequestsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final onLogin = state.matchedLocation == '/login';
      final onOnboarding = state.matchedLocation == '/onboarding';

      // Tant que l'état d'authentification n'est pas encore connu, on ne
      // redirige pas pour éviter un flash vers /login.
      if (authState.isLoading && !authState.hasValue) return null;

      final user = authState.value;
      if (user == null) {
        return onLogin ? null : '/login';
      }

      if (structureState.isLoading && !structureState.hasValue) return null;

      final structure = structureState.value;
      final configured = structure?.configurationTerminee ?? false;

      if (!configured) {
        return onOnboarding ? null : '/onboarding';
      }

      if (onLogin || onOnboarding) return '/dashboard';
      return null;
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
