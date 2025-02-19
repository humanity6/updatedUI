// lib/models/service.dart
class Service {
  final String id;
  final String name;
  final double price;
  bool isSelected;

  Service({
    required this.id,
    required this.name,
    required this.price,
    this.isSelected = false,
  });
}