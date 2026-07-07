class StockAlert {
  const StockAlert({
    required this.id,
    required this.productId,
    required this.minimumQuantity,
    this.isActive = true,
  });

  final String id;
  final String productId;
  final int minimumQuantity;
  final bool isActive;

  StockAlert copyWith({
    String? id,
    String? productId,
    int? minimumQuantity,
    bool? isActive,
  }) {
    return StockAlert(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'minimumQuantity': minimumQuantity,
      'isActive': isActive,
    };
  }

  factory StockAlert.fromMap(Map<String, dynamic> map) {
    return StockAlert(
      id: map['id'].toString(),
      productId: map['productId'].toString(),
      minimumQuantity: int.parse(map['minimumQuantity'].toString()),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'StockAlert('
        'id: $id, '
        'productId: $productId, '
        'minimumQuantity: $minimumQuantity, '
        'isActive: $isActive'
        ')';
  }
}
