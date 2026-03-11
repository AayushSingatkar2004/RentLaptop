// lib/data/repositories/due_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/due_model.dart';

final dueRepositoryProvider = Provider((ref) => DueRepository());

class DueRepository {
  final _sb = Supabase.instance.client;

  // Fetch all pending/partial dues sorted by most overdue first
  Future<List<DueModel>> fetchPendingDues() async {
    final data = await _sb
        .from('dues')
        .select('*, customers(name, phone), rentals(*, laptops(model))')
        .inFilter('status', ['pending', 'partial'])
        .order('due_date', ascending: true);
    return (data as List).map((e) => DueModel.fromJson(e)).toList();
  }

  // Fetch dues for a specific rental
  Future<List<DueModel>> fetchByRental(int rentalId) async {
    final data = await _sb
        .from('dues')
        .select()
        .eq('rental_id', rentalId)
        .order('due_date');
    return (data as List).map((e) => DueModel.fromJson(e)).toList();
  }

  // Record payment — calls Edge Function
  Future<Map<String, dynamic>> recordPayment({
    required int dueId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    final res = await _sb.functions.invoke('record_payment', body: {
      'due_id':           dueId,
      'amount':           amount,
      'payment_mode':     paymentMode,
      'reference_number': referenceNumber,
      'notes':            notes,
    });
    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Failed to record payment');
    }
    return res.data as Map<String, dynamic>;
  }

  // Count overdue dues (for dashboard)
  Future<int> countOverdue() async {
    final res = await _sb
        .from('dues')
        .select('id')
        .inFilter('status', ['pending', 'partial'])
        .lt('due_date', DateTime.now().toIso8601String());
    return (res as List).length;
  }
}