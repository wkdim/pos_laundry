class PaymentType {
  final int? id;
  final String name;

  PaymentType({this.id, required this.name});

  factory PaymentType.fromMap(Map<String, dynamic> map) {
    return PaymentType(
      id: map['PaymentTypeID'] as int?,
      name: map['PaymentTypeName'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'PaymentTypeID': id, 'PaymentTypeName': name};
  }
}
