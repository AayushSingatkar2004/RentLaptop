// lib/providers/due_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/due_model.dart';
import '../data/repositories/due_repository.dart';

class DuesNotifier extends StateNotifier<AsyncValue<List<DueModel>>> {
  final DueRepository _repo;

  DuesNotifier(this._repo) : super(const AsyncLoading()) {
    _fetch();
  }

  Future<void> _fetch() async {
    state = const AsyncLoading();
    try {
      final data = await _repo.fetchPendingDues();
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> recordPayment({
    required int dueId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    await _repo.recordPayment(
      dueId: dueId,
      amount: amount,
      paymentMode: paymentMode,
      referenceNumber: referenceNumber,
      notes: notes,
    );
    await _fetch();
  }
}

final duesNotifierProvider =
    StateNotifierProvider<DuesNotifier, AsyncValue<List<DueModel>>>((ref) {
  return DuesNotifier(ref.read(dueRepositoryProvider));
});