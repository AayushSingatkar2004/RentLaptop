// lib/providers/rental_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/rental_repository.dart';

class RentalNotifier extends StateNotifier<AsyncValue<void>> {
  final RentalRepository _repo;

  RentalNotifier(this._repo) : super(const AsyncData(null));

  Future<Map<String, dynamic>> createRental(Map<String, dynamic> body) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.createRental(body);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeRental(int rentalId, bool returnDeposit) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.completeRental(rentalId, returnDeposit);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final rentalNotifierProvider =
    StateNotifierProvider<RentalNotifier, AsyncValue<void>>((ref) {
  return RentalNotifier(ref.read(rentalRepositoryProvider));
});