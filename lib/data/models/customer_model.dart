// lib/data/models/customer_model.dart

import 'rental_model.dart';

class CustomerModel {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String? idProofType;
  final String idProofNumber;
  final String? idProofDocUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<RentalModel>? rentals;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.idProofType,
    required this.idProofNumber,
    this.idProofDocUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.rentals,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    List<RentalModel>? rentals;
    try {
      if (json['rentals'] != null) {
        rentals = (json['rentals'] as List)
            .map((r) => RentalModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      rentals = [];
    }

    return CustomerModel(
      id:            _parseInt(json['id']),
      name:          (json['name'] as String?) ?? '',
      phone:         (json['phone'] as String?) ?? '',
      address:       (json['address'] as String?) ?? '',
      idProofType:   json['id_proof_type'] as String?,
      idProofNumber: (json['id_proof_number'] as String?) ?? '',
      idProofDocUrl: json['id_proof_doc_url'] as String?,
      status:        (json['status'] as String?) ?? 'inactive',
      createdAt:     _parseDate(json['created_at']),
      updatedAt:     json['updated_at'] != null ? _parseDate(json['updated_at']) : null,
      deletedAt:     json['deleted_at'] != null ? _parseDate(json['deleted_at']) : null,
      rentals:       rentals,
    );
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  bool get isActive   => status == 'active';
  bool get isInactive => status == 'inactive';

  RentalModel? get activeRental =>
      rentals?.where((r) => r.status == 'active').firstOrNull;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}