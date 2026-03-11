// lib/data/models/transaction_model.dart

class TransactionModel {
  final int id;
  final String type;
  final int? rentalId;
  final int customerId;
  final int? dueId;
  final double amount;
  final String? description;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    this.rentalId,
    required this.customerId,
    this.dueId,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id:          json['id'] as int,
    type:        json['type'] as String,
    rentalId:    json['rental_id'] as int?,
    customerId:  json['customer_id'] as int,
    dueId:       json['due_id'] as int?,
    amount:      (json['amount'] as num).toDouble(),
    description: json['description'] as String?,
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  bool get isCredit => amount > 0;
  bool get isDebit  => amount < 0;
}