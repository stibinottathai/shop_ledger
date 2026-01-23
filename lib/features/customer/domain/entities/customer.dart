import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String? id;
  final String name;
  final String phone;
  final String? gstNumber;
  final DateTime? createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    this.gstNumber,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone, gstNumber, createdAt];
}
