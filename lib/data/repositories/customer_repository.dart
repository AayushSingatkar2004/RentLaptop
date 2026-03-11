// lib/data/repositories/customer_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

class CustomerRepository {
  final _sb = Supabase.instance.client;

  // Fetch all customers with their rentals + laptop info
  Future<List<CustomerModel>> fetchAll({String? search, String? status}) async {
    final builder = _sb
        .from('customers')
        .select('*, rentals(*, laptops(model, serial_number))');

    // only include rows where deleted_at IS NULL
    builder.filter('deleted_at', 'is', null);

    if (status != null && status != 'all') {
      builder.eq('status', status);
    }

    builder.order('created_at', ascending: false);

    final data = await builder;

    List<CustomerModel> customers =
        (data as List).map((e) => CustomerModel.fromJson(e)).toList();

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      customers = customers
          .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
          .toList();
    }

    return customers;
  }

  // Single customer with full joins (for detail screen)
  Future<CustomerModel> fetchById(int id) async {
    final data = await _sb
        .from('customers')
        .select('*, rentals(*, laptops(*), dues(*), payments(*))')
        .eq('id', id)
        .single();
    return CustomerModel.fromJson(data);
  }

  // Toggle active / inactive
  Future<void> toggleStatus(int id, String newStatus) async {
    await _sb.from('customers').update({'status': newStatus}).eq('id', id);
    await _sb.from('audit_logs').insert({
      'entity_type': 'customer',
      'entity_id': id,
      'action': 'status_change',
      'new_values': {'status': newStatus},
    });
  }

  // Soft delete (never hard delete)
  Future<void> softDelete(int id) async {
    await _sb.from('customers').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    await _sb.from('audit_logs').insert({
      'entity_type': 'customer',
      'entity_id': id,
      'action': 'delete',
    });
  }

  // Update profile
  Future<void> updateProfile(int id, Map<String, dynamic> fields) async {
    await _sb.from('customers').update(fields).eq('id', id);
    await _sb.from('audit_logs').insert({
      'entity_type': 'customer',
      'entity_id': id,
      'action': 'update',
      'new_values': fields,
    });
  }
}
