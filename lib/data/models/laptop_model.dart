// lib/data/models/laptop_model.dart

class LaptopModel {
  final int id;
  final String uuid;
  final String serialNumber;
  final String model;
  final String? brand;
  final String status; // available | rented | damaged | under_repair
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const LaptopModel({
    required this.id,
    required this.uuid,
    required this.serialNumber,
    required this.model,
    this.brand,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory LaptopModel.fromJson(Map<String, dynamic> json) => LaptopModel(
    id:           json['id'] as int,
    uuid:         json['uuid'] as String,
    serialNumber: json['serial_number'] as String,
    model:        json['model'] as String,
    brand:        json['brand'] as String?,
    status:       json['status'] as String,
    notes:        json['notes'] as String?,
    createdAt:    DateTime.parse(json['created_at'] as String),
    updatedAt:    json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    deletedAt:    json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id':            id,
    'uuid':          uuid,
    'serial_number': serialNumber,
    'model':         model,
    'brand':         brand,
    'status':        status,
    'notes':         notes,
    'created_at':    createdAt.toIso8601String(),
  };

  String get displayName => brand != null ? '$brand $model' : model;

  bool get isAvailable   => status == 'available';
  bool get isRented      => status == 'rented';
  bool get isDamaged     => status == 'damaged';
  bool get isUnderRepair => status == 'under_repair';

  LaptopModel copyWith({
    String? status,
    String? notes,
  }) => LaptopModel(
    id: id, uuid: uuid, serialNumber: serialNumber,
    model: model, brand: brand,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt,
  );
}