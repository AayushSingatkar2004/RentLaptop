// lib/screens/customers/customers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['all', 'active', 'inactive'].map((s) {
                return ChoiceChip(
                  label: Text(s == 'all' ? 'All' : s.capitalize()),
                  selected: _statusFilter == s,
                  onSelected: (_) {
                    setState(() => _statusFilter = s);
                    ref.read(customersNotifierProvider.notifier).filterByStatus(s);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchCustomers,
                  border: InputBorder.none,
                ),
                onChanged: (v) =>
                    ref.read(customersNotifierProvider.notifier).search(v),
              )
            : const Text(AppStrings.customers),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                ref.read(customersNotifierProvider.notifier).search('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customersNotifierProvider.notifier).refresh(),
        child: customersAsync.when(
          loading: () => const LoadingShimmer(),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Error: $e'),
              TextButton(
                onPressed: () => ref.read(customersNotifierProvider.notifier).refresh(),
                child: const Text(AppStrings.retry),
              ),
            ]),
          ),
          data: (customers) => customers.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: AppStrings.noCustomers,
                  subtitle: 'Add your first customer to get started',
                  actionLabel: AppStrings.addCustomer,
                  onAction: () => context.go(AppRoutes.addCustomer),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: customers.length,
                  itemBuilder: (_, i) => _CustomerCard(
                    customer: customers[i],
                    onTap: () => context.go('/customers/${customers[i].id}'),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.addCustomer),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rental = customer.activeRental;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(customer.initials,
            style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(customer.name,
              style: const TextStyle(fontWeight: FontWeight.w600))),
            StatusBadge(status: customer.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customer.phone,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (rental?.laptop != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.laptop_mac, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(rental!.laptop!.displayName,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ]),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      ),
    );
  }
}

extension StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}