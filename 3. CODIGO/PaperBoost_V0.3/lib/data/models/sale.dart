import 'sale_item.dart';

enum SaleStatus {
  pending,
  completed,
  cancelled,
}

enum PaymentMethod {
  cash,
  card,
  transfer,
  other,
}

class Sale {
  const Sale({
    required this.id,
    required this.saleNumber,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.observations = '',
    this.customerName = '',
    this.customerEmail = '',
  });

  final String id;
  final String saleNumber;
  final List<SaleItem> items;
  final double subtotal;
  final double taxAmount;
  final double total;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final DateTime createdAt;
  final String observations;
  final String customerName;
  final String customerEmail;

  double get taxRate => taxAmount > 0 ? (taxAmount / subtotal) * 100 : 0;

  bool get isPending => status == SaleStatus.pending;
  bool get isCompleted => status == SaleStatus.completed;
  bool get isCancelled => status == SaleStatus.cancelled;

  Sale copyWith({
    String? id,
    String? saleNumber,
    List<SaleItem>? items,
    double? subtotal,
    double? taxAmount,
    double? total,
    PaymentMethod? paymentMethod,
    SaleStatus? status,
    DateTime? createdAt,
    String? observations,
    String? customerName,
    String? customerEmail,
  }) {
    return Sale(
      id: id ?? this.id,
      saleNumber: saleNumber ?? this.saleNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      observations: observations ?? this.observations,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleNumber': saleNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'observations': observations,
      'customerName': customerName,
      'customerEmail': customerEmail,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'].toString(),
      saleNumber: map['saleNumber'].toString(),
      items: List<SaleItem>.from(
        (map['items'] as List).map(
          (item) => SaleItem.fromMap(
            Map<String, dynamic>.from(item),
          ),
        ),
      ),
      subtotal: double.parse(map['subtotal'].toString()),
      taxAmount: double.parse(map['taxAmount'].toString()),
      total: double.parse(map['total'].toString()),
      paymentMethod: PaymentMethod.values.firstWhere(
        (method) => method.name == map['paymentMethod'],
        orElse: () => PaymentMethod.other,
      ),
      status: SaleStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SaleStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'].toString()),
      observations: map['observations']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerEmail: map['customerEmail']?.toString() ?? '',
    );
  }
}
