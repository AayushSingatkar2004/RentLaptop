// lib/data/models/due_model.dart

class DueModel {
  final int id;
  final int rentalId;
  final int customerId;
  final DateTime dueDate;
  final double amountDue;
  final double amountPaid;
  final String status;
  final String? cycleLabel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? customerName;
  final String? customerPhone;
  final String? laptopModel;

  const DueModel({
    required this.id,
    required this.rentalId,
    required this.customerId,
    required this.dueDate,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    this.cycleLabel,
    required this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerPhone,
    this.laptopModel,
  });

  factory DueModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>?;
    final rental   = json['rentals']   as Map<String, dynamic>?;
    final laptop   = rental?['laptops'] as Map<String, dynamic>?;

    return DueModel(
      id:           _parseInt(json['id']),
      rentalId:     _parseInt(json['rental_id']),
      customerId:   _parseInt(json['customer_id']),
      dueDate:      _parseDate(json['due_date']),
      amountDue:    _parseDouble(json['amount_due']),
      amountPaid:   _parseDouble(json['amount_paid']),
      status:       (json['status'] as String?) ?? 'pending',
      cycleLabel:   json['cycle_label'] as String?,
      createdAt:    _parseDate(json['created_at']),
      updatedAt:    json['updated_at'] != null ? _parseDate(json['updated_at']) : null,
      customerName:  customer?['name']  as String?,
      customerPhone: customer?['phone'] as String?,
      laptopModel:   laptop?['model']   as String?,
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

  double get balance => amountDue - amountPaid;
  bool get isPending => status == 'pending';
  bool get isPartial => status == 'partial';
  bool get isPaid    => status == 'paid';
  bool get isWaived  => status == 'waived';

  int get daysOverdue {
    final diff = DateTime.now().difference(dueDate).inDays;
    return diff > 0 ? diff : 0;
  }

  bool get isOverdue => daysOverdue > 0 && !isPaid && !isWaived;
}