// lib/screens/customers/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/rental_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/rental_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Detail')),
      body: customerAsync.when(
        loading: () => const LoadingShimmer(itemCount: 4),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customer) => _CustomerDetailBody(customer: customer),
      ),
    );
  }
}

class _CustomerDetailBody extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const _CustomerDetailBody({required this.customer});

  @override
  ConsumerState<_CustomerDetailBody> createState() => _CustomerDetailBodyState();
}

class _CustomerDetailBodyState extends ConsumerState<_CustomerDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus() async {
    final newStatus = widget.customer.isActive ? 'inactive' : 'active';
    final ok = await showConfirmDialog(context,
      title: 'Change Status',
      message: 'Mark this customer as $newStatus?',
      confirmText: 'Confirm',
    );
    if (ok) {
      await ref.read(customersNotifierProvider.notifier).toggleStatus(
        widget.customer.id, newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer marked as $newStatus')),
        );
        ref.invalidate(customerDetailProvider(widget.customer.id));
      }
    }
  }

  Future<void> _showCompleteRentalSheet(RentalModel rental) async {
    bool returnDeposit = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Complete Rental',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Laptop: ${rental.laptop?.displayName ?? 'N/A'}',
                style: const TextStyle(color: AppColors.textSecondary)),
              Text('Deposit: ₹${rental.depositAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.returnDeposit),
                subtitle: Text('₹${rental.depositAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.primary)),
                value: returnDeposit,
                onChanged: (v) => setS(() => returnDeposit = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref.read(rentalNotifierProvider.notifier)
                        .completeRental(rental.id, returnDeposit);
                    ref.invalidate(customerDetailProvider(widget.customer.id));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rental completed!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'),
                          backgroundColor: AppColors.damaged),
                      );
                    }
                  }
                },
                child: const Text('Confirm Complete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final rental = c.activeRental;
    final fmt = DateFormat('dd MMM yyyy');

    return Column(
      children: [
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                child: Text(c.initials,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(c.phone,
                    style: const TextStyle(color: AppColors.textSecondary)),
                ],
              )),
              GestureDetector(
                onTap: _toggleStatus,
                child: StatusBadge(status: c.status),
              ),
            ]),
            const SizedBox(height: 16),
            // Info rows
            _InfoRow(Icons.location_on_outlined, c.address),
            _InfoRow(Icons.badge_outlined, '${c.idProofType ?? 'ID'}: ${c.idProofNumber}'),
            _InfoRow(Icons.calendar_today_outlined, 'Member since ${fmt.format(c.createdAt)}'),
          ]),
        ),

        // Active rental card
        if (rental != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.laptop_mac, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rental.laptop?.displayName ?? 'Laptop',
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        color: AppColors.primary))),
                  rental.isOverdue
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.damaged,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('OVERDUE',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      )
                    : Text('${rental.daysLeft} days left',
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 16, runSpacing: 4, children: [
                  _RentalChip('Type', rental.rentalType),
                  _RentalChip('Start', fmt.format(rental.startDate)),
                  _RentalChip('End',   fmt.format(rental.endDate)),
                  _RentalChip('Rent',  '₹${rental.rentAmount.toStringAsFixed(0)}/cycle'),
                  _RentalChip('Deposit', '₹${rental.depositAmount.toStringAsFixed(0)}'),
                ]),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showCompleteRentalSheet(rental),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44)),
                  child: const Text(AppStrings.markComplete),
                ),
              ],
            ),
          ),

        // Tabs
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Payments'),
              Tab(text: 'Dues'),
              Tab(text: 'Audit'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PaymentsTab(customer: c),
              _DuesTab(customer: c),
              _AuditTab(customer: c),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ]),
  );
}

class _RentalChip extends StatelessWidget {
  final String label;
  final String value;
  const _RentalChip(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      Text(value,  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.primary)),
    ],
  );
}

class _PaymentsTab extends StatelessWidget {
  final CustomerModel customer;
  const _PaymentsTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    final allPayments = customer.rentals
        ?.expand((r) => r.dues ?? [])
        .toList() ?? [];
    if (allPayments.isEmpty) {
      return const Center(child: Text('No payments yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allPayments.length,
      itemBuilder: (_, i) {
        final due = allPayments[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.payment, color: AppColors.primary),
            title: Text(due.cycleLabel ?? 'Due #${due.id}'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(due.dueDate)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${due.amountPaid.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                StatusBadge(status: due.status),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DuesTab extends StatelessWidget {
  final CustomerModel customer;
  const _DuesTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    final dues = customer.rentals?.expand((r) => r.dues ?? []).toList() ?? [];
    if (dues.isEmpty) return const Center(child: Text('No dues found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dues.length,
      itemBuilder: (_, i) {
        final d = dues[i];
        return Card(
          child: ListTile(
            title: Text(d.cycleLabel ?? 'Due #${d.id}'),
            subtitle: Text('Due: ${DateFormat('dd MMM yyyy').format(d.dueDate)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${d.amountDue.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                StatusBadge(status: d.status),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuditTab extends StatelessWidget {
  final CustomerModel customer;
  const _AuditTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Audit trail available in Supabase Dashboard',
        style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}