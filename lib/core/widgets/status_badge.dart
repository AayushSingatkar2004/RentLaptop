// lib/core/widgets/status_badge.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final label = _labelFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorFor(String s) => switch (s) {
    'available'    => AppColors.available,
    'rented'       => AppColors.rented,
    'damaged'      => AppColors.damaged,
    'under_repair' => AppColors.underRepair,
    'active'       => AppColors.available,
    'inactive'     => AppColors.textSecondary,
    'pending'      => AppColors.pending,
    'partial'      => AppColors.partial,
    'paid'         => AppColors.paid,
    'waived'       => AppColors.waived,
    'completed'    => AppColors.textSecondary,
    'cancelled'    => AppColors.damaged,
    _              => AppColors.textSecondary,
  };

  String _labelFor(String s) => switch (s) {
    'available'    => 'Available',
    'rented'       => 'Rented',
    'damaged'      => 'Damaged',
    'under_repair' => 'Under Repair',
    'active'       => 'Active',
    'inactive'     => 'Inactive',
    'pending'      => 'Pending',
    'partial'      => 'Partial',
    'paid'         => 'Paid',
    'waived'       => 'Waived',
    'completed'    => 'Completed',
    'cancelled'    => 'Cancelled',
    _              => s,
  };
}