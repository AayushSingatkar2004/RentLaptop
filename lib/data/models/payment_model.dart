// lib/data/models/payment_model.dart

class PaymentModel {
  final int id;
  final int dueId;
  final int rentalId;
  final int customerId;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMode;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.dueId,
    required this.rentalId,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    this.paymentMode,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id:              json['id'] as int,
    dueId:           json['due_id'] as int,
    rentalId:        json['rental_id'] as int,
    customerId:      json['customer_id'] as int,
    amount:          (json['amount'] as num).toDouble(),
    paymentDate:     DateTime.parse(json['payment_date'] as String),
    paymentMode:     json['payment_mode'] as String?,
    referenceNumber: json['reference_number'] as String?,
    notes:           json['notes'] as String?,
    createdAt:       DateTime.parse(json['created_at'] as String),
  );
}