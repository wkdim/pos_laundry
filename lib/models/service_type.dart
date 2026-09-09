class ServiceType {
  final int? id;
  final String name;
  final String? description;
  final double? price;

  ServiceType({this.id, required this.name, this.description, this.price});

  factory ServiceType.fromMap(Map<String, dynamic> map) {
    return ServiceType(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'price': price};
  }
}
