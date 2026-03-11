// lib/data/repositories/laptop_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/laptop_model.dart';

final laptopRepositoryProvider = Provider((ref) => LaptopRepository());

class LaptopRepository {
  final _sb = Supabase.instance.client;

  // Fetch all laptops (not soft-deleted), optional status filter
  Future<List<LaptopModel>> fetchAll({String? status}) async {
    final builder = _sb.from('laptops').select();

    // exclude soft‑deleted rows by checking deleted_at is null
    builder.filter('deleted_at', 'is', null);

    if (status != null) {
      builder.eq('status', status);
    }

    builder.order('created_at', ascending: false);

    final data = await builder;

    return (data as List).map((e) => LaptopModel.fromJson(e)).toList();
  }

  // Fetch only available laptops (for rental dropdown)
  Future<List<LaptopModel>> fetchAvailable() async {
    final data = await _sb
        .from('laptops')
        .select()
        .eq('status', 'available')
        .filter('deleted_at', 'is', null)
        .order('model');
    return (data as List).map((e) => LaptopModel.fromJson(e)).toList();
  }

  // Add a new laptop
  Future<LaptopModel> addLaptop({
    required String uuid,
    required String serialNumber,
    required String model,
    String? brand,
    required String status,
    String? notes,
  }) async {
    final data = await _sb
        .from('laptops')
        .insert({
          'uuid': uuid,
          'serial_number': serialNumber,
          'model': model,
          'brand': brand,
          'status': status,
          'notes': notes,
        })
        .select()
        .single();
    await _sb.from('audit_logs').insert({
      'entity_type': 'laptop',
      'entity_id': data['id'],
      'action': 'create',
      'new_values': data,
    });
    return LaptopModel.fromJson(data);
  }

  // Update laptop status
  Future<void> updateStatus(int id, String newStatus) async {
    final old =
        await _sb.from('laptops').select('status').eq('id', id).single();
    await _sb.from('laptops').update({'status': newStatus}).eq('id', id);
    await _sb.from('audit_logs').insert({
      'entity_type': 'laptop',
      'entity_id': id,
      'action': 'status_change',
      'old_values': {'status': old['status']},
      'new_values': {'status': newStatus},
    });
  }

  // Check UUID uniqueness before saving
  Future<bool> isUuidUnique(String uuid, {int? excludeId}) async {
    var query = _sb.from('laptops').select('id').eq('uuid', uuid);
    final data = await query;
    if (excludeId != null) {
      return (data as List).every((e) => e['id'] == excludeId);
    }
    return (data as List).isEmpty;
  }

  // Check serial uniqueness before saving
  Future<bool> isSerialUnique(String serial, {int? excludeId}) async {
    var query = _sb.from('laptops').select('id').eq('serial_number', serial);
    final data = await query;
    if (excludeId != null) {
      return (data as List).every((e) => e['id'] == excludeId);
    }
    return (data as List).isEmpty;
  }

  // Soft delete
  Future<void> softDelete(int id) async {
    await _sb.from('laptops').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
