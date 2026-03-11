// lib/data/models/rental_model.dart

import 'due_model.dart';
import 'laptop_model.dart';

class RentalModel {
  final int id;
  final int customerId;
  final int laptopId;
  final String rentalType;
  final int? durationCount;
  final DateTime startDate;
  final DateTime endDate;
  final double rentAmount;
  final double depositAmount;
  final bool depositReturned;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final LaptopModel? laptop;
  final List<DueModel>? dues;

  const RentalModel({
    required this.id,
    required this.customerId,
    required this.laptopId,
    required this.rentalType,
    this.durationCount,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.depositAmount,
    required this.depositReturned,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.laptop,
    this.dues,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    LaptopModel? laptop;
    List<DueModel>? dues;
    try {
      if (json['laptops'] != null) {
        laptop = LaptopModel.fromJson(json['laptops'] as Map<String, dynamic>);
      }
    } catch (_) {}
    try {
      if (json['dues'] != null) {
        dues = (json['dues'] as List)
            .map((d) => DueModel.fromJson(d as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return RentalModel(
      id:              _parseInt(json['id']),
      customerId:      _parseInt(json['customer_id']),
      laptopId:        _parseInt(json['laptop_id']),
      rentalType:      (json['rental_type'] as String?) ?? 'monthly',
      durationCount:   json['duration_count'] != null ? _parseInt(json['duration_count']) : null,
      startDate:       _parseDate(json['start_date']),
      endDate:         _parseDate(json['end_date']),
      rentAmount:      _parseDouble(json['rent_amount']),
      depositAmount:   _parseDouble(json['deposit_amount']),
      depositReturned: json['deposit_returned'] as bool? ?? false,
      status:          (json['status'] as String?) ?? 'active',
      notes:           json['notes'] as String?,
      createdAt:       _parseDate(json['created_at']),
      updatedAt:       json['updated_at'] != null ? _parseDate(json['updated_at']) : null,
      completedAt:     json['completed_at'] != null ? _parseDate(json['completed_at']) : null,
      laptop:          laptop,
      dues:            dues,
    );
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  bool get isActive    => status == 'active';
  bool get isCompleted => status == 'completed';

  int get daysLeft {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  bool get isOverdue => DateTime.now().isAfter(endDate) && status == 'active';
}