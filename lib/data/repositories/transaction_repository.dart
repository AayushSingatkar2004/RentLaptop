// lib/data/repositories/transaction_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laptop_rental_admin/data/models/transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final transactionRepositoryProvider = Provider((ref) => TransactionRepository());

class TransactionRepository {
  final _sb = Supabase.instance.client;

  // Fetch all transactions for a customer (paginated)
  Future<List<TransactionModel>> fetchByCustomer(int customerId, {int page = 0}) async {
    final data = await _sb
        .from('transactions')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .range(page * 20, (page + 1) * 20 - 1);
    return (data as List).map((e) => TransactionModel.fromJson(e)).toList();
  }
}