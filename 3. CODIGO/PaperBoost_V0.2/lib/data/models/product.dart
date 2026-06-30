enum ProductStatus {
  active,
  inactive,
}

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.location,
    this.status = ProductStatus.active,
  });

  final String id;
  final String sku;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String location;
  final ProductStatus status;

  bool get isActive => status == ProductStatus.active;

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    double? price,
    int? stock,
    String? category,
    String? location,
    ProductStatus? status,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'location': location,
      'status': status.name,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final statusName = map['status']?.toString();

    return Product(
      id: map['id'].toString(),
      sku: map['sku'].toString(),
      name: map['name'].toString(),
      price: _toDouble(map['price']),
      stock: _toInt(map['stock']),
      category: map['category'].toString(),
      location: map['location'].toString(),
      status: ProductStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ProductStatus.active,
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  String toString() {
    return 'Product('
        'id: $id, '
        'sku: $sku, '
        'name: $name, '
        'price: $price, '
        'stock: $stock, '
        'category: $category, '
        'location: $location, '
        'status: ${status.name}'
        ')';
  }
}