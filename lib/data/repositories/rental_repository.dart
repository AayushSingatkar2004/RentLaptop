// lib/data/repositories/rental_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final rentalRepositoryProvider = Provider((ref) => RentalRepository());

class RentalRepository {
  final _sb = Supabase.instance.client;

  // Create rental — calls Edge Function for atomic operation
  Future<Map<String, dynamic>> createRental(Map<String, dynamic> body) async {
    final res = await _sb.functions.invoke('create_rental', body: body);
    if (res.status != 201) {
      throw Exception(res.data['error'] ?? 'Failed to create rental');
    }
    return res.data as Map<String, dynamic>;
  }

  // Complete rental — calls Edge Function
  Future<Map<String, dynamic>> completeRental(int rentalId, bool returnDeposit) async {
    final res = await _sb.functions.invoke('complete_rental', body: {
      'rental_id':      rentalId,
      'return_deposit': returnDeposit,
    });
    if (res.status != 200) {
      throw Exception(res.data['error'] ?? 'Failed to complete rental');
    }
    return res.data as Map<String, dynamic>;
  }
}