// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: AppStrings.logout,
            onPressed: () async {
              final ok = await showConfirmDialog(context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                confirmText: 'Logout',
                isDanger: true,
              );
              if (ok) ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back, Admin 👋',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Here\'s what\'s happening today',
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),

            statsAsync.when(
              loading: () => _buildSkeleton(),
              error:   (e, _) => _buildError(e, () => ref.invalidate(dashboardStatsProvider)),
              data:    (stats) => _buildGrid(context, stats),
            ),
            const SizedBox(height: 24),

            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(title: AppStrings.activeCustomers,
          value: stats.activeCustomers.toString(),
          icon: Icons.people_outline, color: AppColors.cardBlue,
          onTap: () => context.go(AppRoutes.customers)),
        StatCard(title: AppStrings.totalLaptops,
          value: stats.totalLaptops.toString(),
          icon: Icons.laptop_mac_outlined, color: AppColors.cardTeal,
          onTap: () => context.go(AppRoutes.laptops)),
        StatCard(title: AppStrings.rented,
          value: stats.rentedLaptops.toString(),
          icon: Icons.assignment_outlined, color: AppColors.cardPurple,
          onTap: () => context.go(AppRoutes.laptops)),
        StatCard(title: AppStrings.available,
          value: stats.availableLaptops.toString(),
          icon: Icons.check_circle_outline, color: AppColors.cardGreen,
          onTap: () => context.go(AppRoutes.laptops)),
        StatCard(title: AppStrings.overdueDues,
          value: stats.overdueDues.toString(),
          icon: Icons.warning_amber_outlined,
          color: stats.overdueDues > 0 ? AppColors.cardRed : AppColors.cardGreen,
          onTap: () => context.go(AppRoutes.dues)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.person_add_outlined,  'New Customer', AppColors.cardGreen,  AppRoutes.addCustomer),
      (Icons.laptop_mac_outlined,  'Add Laptop',   AppColors.cardTeal,   AppRoutes.addLaptop),
      (Icons.receipt_long_outlined,'View Dues',    AppColors.cardOrange, AppRoutes.dues),
      (Icons.people_outline,       'Customers',    AppColors.cardBlue,   AppRoutes.customers),
    ];
    return Row(
      children: actions.map((a) {
        final (icon, label, color, route) = a;
        return Expanded(child: GestureDetector(
          onTap: () => context.go(route),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            ]),
          ),
        ));
      }).toList(),
    );
  }

  Widget _buildSkeleton() => GridView.count(
    crossAxisCount: 2, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
    children: List.generate(5, (_) => Container(
      decoration: BoxDecoration(
        color: AppColors.divider, borderRadius: BorderRadius.circular(12)),
    )),
  );

  Widget _buildError(Object e, VoidCallback onRetry) => Center(child: Column(children: [
    Text('Failed to load stats'),
    TextButton(onPressed: onRetry, child: const Text('Retry')),
  ]));
}