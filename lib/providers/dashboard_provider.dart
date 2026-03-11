// lib/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardStats {
  final int activeCustomers;
  final int totalLaptops;
  final int rentedLaptops;
  final int availableLaptops;
  final int overdueDues;

  const DashboardStats({
    required this.activeCustomers,
    required this.totalLaptops,
    required this.rentedLaptops,
    required this.availableLaptops,
    required this.overdueDues,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final sb = Supabase.instance.client;

  final results = await Future.wait([
    sb.from('customers').select('id').eq('status', 'active').isFilter('deleted_at', null),
    sb.from('laptops').select('id').isFilter('deleted_at', null),
    sb.from('laptops').select('id').eq('status', 'rented'),
    sb.from('laptops').select('id').eq('status', 'available'),
    sb.from('dues').select('id')
        .inFilter('status', ['pending', 'partial'])
        .lt('due_date', DateTime.now().toIso8601String()),
  ]);

  return DashboardStats(
    activeCustomers:  (results[0] as List).length,
    totalLaptops:     (results[1] as List).length,
    rentedLaptops:    (results[2] as List).length,
    availableLaptops: (results[3] as List).length,
    overdueDues:      (results[4] as List).length,
  );
});