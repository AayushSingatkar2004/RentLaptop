// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/customers/customers_list_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/laptops/laptops_list_screen.dart';
import '../../screens/laptops/add_laptop_screen.dart';
import '../../screens/dues/dues_screen.dart';

class AppRoutes {
  static const String login          = '/login';
  static const String dashboard      = '/dashboard';
  static const String customers      = '/customers';
  static const String addCustomer    = '/customers/new';
  static const String customerDetail = '/customers/:id';
  static const String laptops        = '/laptops';
  static const String addLaptop      = '/laptops/new';
  static const String dues           = '/dues';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final onLogin = state.uri.path == AppRoutes.login;
      if (!isLoggedIn && !onLogin) return AppRoutes.login;
      if (isLoggedIn && onLogin)   return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // Login — no shell, no bottom nav
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),

      // Everything else — inside shell so bottom nav always visible
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (_, __) => const CustomersListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const AddCustomerScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CustomerDetailScreen(customerId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.laptops,
            builder: (_, __) => const LaptopsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const AddLaptopScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.dues,
            builder: (_, __) => const DuesScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.path}')),
    ),
  );
});