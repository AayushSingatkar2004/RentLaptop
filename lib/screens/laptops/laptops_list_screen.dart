// lib/screens/laptops/laptops_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/laptop_model.dart';
import '../../providers/laptop_provider.dart';

class LaptopsListScreen extends ConsumerStatefulWidget {
  const LaptopsListScreen({super.key});

  @override
  ConsumerState<LaptopsListScreen> createState() => _LaptopsListScreenState();
}

class _LaptopsListScreenState extends ConsumerState<LaptopsListScreen> {
  String _filter = 'all';

  final _filters = ['all', 'available', 'rented', 'damaged', 'under_repair'];

  final _filterLabels = {
    'all':          'All',
    'available':    'Available',
    'rented':       'Rented',
    'damaged':      'Damaged',
    'under_repair': 'Under Repair',
  };

  final _filterColors = {
    'all':          AppColors.primary,
    'available':    AppColors.available,
    'rented':       AppColors.rented,
    'damaged':      AppColors.damaged,
    'under_repair': AppColors.underRepair,
  };

  void _showStatusSheet(LaptopModel laptop) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status — ${laptop.displayName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...['available', 'damaged', 'under_repair'].map((s) => ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: _filterColors[s] ?? AppColors.primary,
              ),
              title: Text(_filterLabels[s] ?? s),
              selected: laptop.status == s,
              selectedTileColor: AppColors.primaryLight,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(laptopsNotifierProvider.notifier)
                    .updateStatus(laptop.id, s);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status updated to ${_filterLabels[s]}')));
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(LaptopModel laptop) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(laptop.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              StatusBadge(status: laptop.status),
            ]),
            const Divider(height: 24),
            _DetailRow('UUID',   laptop.uuid),
            _DetailRow('Serial', laptop.serialNumber),
            _DetailRow('Model',  laptop.model),
            _DetailRow('Brand',  laptop.brand ?? '—'),
            if (laptop.notes != null) _DetailRow('Notes', laptop.notes!),
            const SizedBox(height: 20),
            if (!laptop.isRented)
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showStatusSheet(laptop);
                },
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44)),
                child: const Text('Change Status'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laptopsAsync = ref.watch(laptopsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.laptops)),
      body: Column(children: [
        // ── Filter chips ──────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _filter == f;
                    final color = _filterColors[f] ?? AppColors.primary;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _filter = f);
                        ref.read(laptopsNotifierProvider.notifier).filterByStatus(f);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _filterLabels[f] ?? f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),

        // ── Laptop list ───────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(laptopsNotifierProvider.notifier).refresh(),
            child: laptopsAsync.when(
              loading: () => const LoadingShimmer(),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data: (laptops) => laptops.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.laptop_mac_outlined,
                      title: _filter == 'all'
                          ? AppStrings.noLaptops
                          : 'No ${_filterLabels[_filter]} laptops',
                      actionLabel: _filter == 'all' ? AppStrings.addLaptop : null,
                      onAction: _filter == 'all'
                          ? () => context.go(AppRoutes.addLaptop) : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: laptops.length,
                      itemBuilder: (_, i) {
                        final l = laptops[i];
                        final color = _filterColors[l.status] ?? AppColors.primary;
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap:      () => _showDetailSheet(l),
                            onLongPress: l.isRented ? null : () => _showStatusSheet(l),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.laptop_mac,
                                      color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(l.uuid,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                    Text('SN: ${l.serialNumber}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  ],
                                )),
                                StatusBadge(status: l.status),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.addLaptop),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 64,
        child: Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13))),
      Expanded(child: Text(value,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}