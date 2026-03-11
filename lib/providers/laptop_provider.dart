// lib/providers/laptop_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/laptop_model.dart';
import '../data/repositories/laptop_repository.dart';

// ── Laptops list notifier ────────────────────────────────────

class LaptopsNotifier extends StateNotifier<AsyncValue<List<LaptopModel>>> {
  final LaptopRepository _repo;
  String _statusFilter = 'all';

  LaptopsNotifier(this._repo) : super(const AsyncLoading()) {
    _fetch();
  }

  Future<void> _fetch() async {
    state = const AsyncLoading();
    try {
      final data = await _repo.fetchAll(
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> filterByStatus(String status) async {
    _statusFilter = status;
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> updateStatus(int id, String newStatus) async {
    await _repo.updateStatus(id, newStatus);
    await _fetch();
  }
}

final laptopsNotifierProvider =
    StateNotifierProvider<LaptopsNotifier, AsyncValue<List<LaptopModel>>>((ref) {
  return LaptopsNotifier(ref.read(laptopRepositoryProvider));
});

// ── Available laptops only (for rental dropdown) ─────────────

final availableLaptopsProvider = FutureProvider<List<LaptopModel>>((ref) {
  return ref.read(laptopRepositoryProvider).fetchAvailable();
});