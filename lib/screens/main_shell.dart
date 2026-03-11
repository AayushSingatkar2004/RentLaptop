// lib/screens/main_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Which tab index is active based on current path
  int _currentIndex(String path) {
    if (path.startsWith('/customers')) return 1;
    if (path.startsWith('/laptops'))   return 2;
    if (path.startsWith('/dues'))      return 3;
    return 0;
  }

  // Is this a detail/add screen (not a root tab screen)?
  bool _isDetailScreen(String path) {
    return path == AppRoutes.addCustomer ||
        path == AppRoutes.addLaptop ||
        path.startsWith('/customers/') ||
        path.startsWith('/laptops/');
  }

  @override
  Widget build(BuildContext context) {
    final path  = GoRouterState.of(context).uri.path;
    final index = _currentIndex(path);
    final isDetail = _isDetailScreen(path);

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back bar — shown on detail/add screens
          if (isDetail)
            Container(
              color: AppColors.surface,
              child: const Divider(height: 1),
            ),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              switch (i) {
                case 0: context.go(AppRoutes.dashboard);
                case 1: context.go(AppRoutes.customers);
                case 2: context.go(AppRoutes.laptops);
                case 3: context.go(AppRoutes.dues);
              }
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            destinations: const [
              NavigationDestination(
                icon:         Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon:         Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people, color: AppColors.primary),
                label: 'Customers',
              ),
              NavigationDestination(
                icon:         Icon(Icons.laptop_mac_outlined),
                selectedIcon: Icon(Icons.laptop_mac, color: AppColors.primary),
                label: 'Laptops',
              ),
              NavigationDestination(
                icon:         Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
                label: 'Dues',
              ),
            ],
          ),
        ],
      ),
    );
  }
}