// lib/screens/dues/dues_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/due_model.dart';
import '../../providers/due_provider.dart';

class DuesScreen extends ConsumerWidget {
  const DuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(duesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dues)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(duesNotifierProvider.notifier).refresh(),
        child: duesAsync.when(
          loading: () => const LoadingShimmer(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (dues) {
            if (dues.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.check_circle_outline,
                title: AppStrings.allClear,
                subtitle: 'No pending or overdue dues',
              );
            }

            final totalOutstanding = dues.fold<double>(0, (sum, d) => sum + d.balance);
            final overdueCount = dues.where((d) => d.isOverdue).length;

            return Column(children: [
              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: AppColors.surface,
                child: Row(children: [
                  Expanded(child: _SummaryTile(
                    label: 'Total Pending',
                    value: '${dues.length}',
                    color: AppColors.primary,
                  )),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  Expanded(child: _SummaryTile(
                    label: 'Overdue',
                    value: '$overdueCount',
                    color: AppColors.overdue,
                  )),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  Expanded(child: _SummaryTile(
                    label: 'Outstanding',
                    value: '₹${totalOutstanding.toStringAsFixed(0)}',
                    color: AppColors.pending,
                  )),
                ]),
              ),
              const Divider(height: 1),

              // Dues list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: dues.length,
                  itemBuilder: (_, i) => _DueCard(
                    due: dues[i],
                    onTap: () => _showPaymentSheet(context, ref, dues[i]),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref, DueModel due) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PaymentSheet(due: due),
    );
  }
}

class _DueCard extends StatelessWidget {
  final DueModel due;
  final VoidCallback onTap;
  const _DueCard({required this.due, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(due.customerName ?? 'Customer #${due.customerId}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              StatusBadge(status: due.status),
            ]),
            const SizedBox(height: 4),
            if (due.customerPhone != null)
              Text(due.customerPhone!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (due.laptopModel != null)
              Row(children: [
                const Icon(Icons.laptop_mac, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(due.laptopModel!,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary)),
              ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(due.cycleLabel ?? 'Due #${due.id}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(fmt.format(due.dueDate),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${due.balance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (due.isOverdue)
                  Text('${due.daysOverdue} ${AppStrings.daysOverdue}',
                    style: const TextStyle(fontSize: 11, color: AppColors.overdue,
                        fontWeight: FontWeight.w600)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _PaymentSheet extends ConsumerStatefulWidget {
  final DueModel due;
  const _PaymentSheet({required this.due});

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  bool _partial = false;
  final _amountCtrl = TextEditingController();
  final _refCtrl    = TextEditingController();
  String _mode      = 'cash';
  bool _loading     = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay(double amount) async {
    setState(() => _loading = true);
    try {
      await ref.read(duesNotifierProvider.notifier).recordPayment(
        dueId:           widget.due.id,
        amount:          amount,
        paymentMode:     _mode,
        referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.damaged));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = widget.due;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record Payment',
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('${due.cycleLabel ?? 'Due #${due.id}'} · ₹${due.balance.toStringAsFixed(0)} remaining',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          // Payment mode
          DropdownButtonFormField<String>(
            value: _mode,
            decoration: const InputDecoration(labelText: AppStrings.paymentMode),
            items: const [
              DropdownMenuItem(value: 'cash',          child: Text('Cash')),
              DropdownMenuItem(value: 'upi',           child: Text('UPI')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              DropdownMenuItem(value: 'other',         child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _mode = v!),
          ),
          const SizedBox(height: 12),

          // Reference number
          TextFormField(
            controller: _refCtrl,
            decoration: const InputDecoration(labelText: AppStrings.referenceNumber),
          ),
          const SizedBox(height: 12),

          // Partial toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Partial Payment'),
            value: _partial,
            onChanged: (v) {
              setState(() => _partial = v);
              if (!v) _amountCtrl.clear();
            },
          ),

          // Partial amount input
          if (_partial) ...[
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (max ₹${due.balance.toStringAsFixed(0)})',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _loading ? null : () {
                if (_partial) {
                  final amt = double.tryParse(_amountCtrl.text);
                  if (amt == null || amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid amount')));
                    return;
                  }
                  if (amt > due.balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        'Amount cannot exceed ₹${due.balance.toStringAsFixed(0)}')));
                    return;
                  }
                  _pay(amt);
                } else {
                  _pay(due.balance);
                }
              },
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_partial ? AppStrings.partialPay : AppStrings.fullPay),
            )),
          ]),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );
}