import 'product.dart';

class SaleItem {
  const SaleItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final Product product;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  SaleItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? unitPrice,
  }) {
    return SaleItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'].toString(),
      product: Product.fromMap(
        Map<String, dynamic>.from(map['product']),
      ),
      quantity: int.parse(map['quantity'].toString()),
      unitPrice: double.parse(map['unitPrice'].toString()),
    );
  }
}
