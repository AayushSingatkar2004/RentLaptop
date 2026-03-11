// lib/providers/customer_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer_model.dart';
import '../data/repositories/customer_repository.dart';

// ── Customers list notifier ──────────────────────────────────

class CustomersNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerRepository _repo;
  String _search = '';
  String _status = 'all';

  CustomersNotifier(this._repo) : super(const AsyncLoading()) {
    _fetch();
  }

  Future<void> _fetch() async {
    state = const AsyncLoading();
    try {
      final data = await _repo.fetchAll(
        search: _search.isEmpty ? null : _search,
        status: _status == 'all' ? null : _status,
      );
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> search(String query) async {
    _search = query;
    await _fetch();
  }

  Future<void> filterByStatus(String status) async {
    _status = status;
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> toggleStatus(int id, String newStatus) async {
    await _repo.toggleStatus(id, newStatus);
    await _fetch();
  }
}

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<CustomerModel>>>((ref) {
  return CustomersNotifier(ref.read(customerRepositoryProvider));
});

// ── Single customer detail ───────────────────────────────────

final customerDetailProvider =
    FutureProvider.family<CustomerModel, int>((ref, id) async {
  return ref.read(customerRepositoryProvider).fetchById(id);
});