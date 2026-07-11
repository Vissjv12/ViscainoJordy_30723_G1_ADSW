import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale.dart';
import 'package:paperboost/data/models/sale_item.dart';

void main() {
  group('Sale', () {
    const product = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Test Product',
      price: 100.0,
      stock: 50,
      category: 'Test',
      location: 'A1',
    );

    final item = SaleItem(
      id: 'ITEM-001',
      product: product,
      quantity: 2,
      unitPrice: 100.0,
    );

    final sale = Sale(
      id: 'SALE-001',
      saleNumber: 'VTA-000001',
      items: [item],
      subtotal: 200.0,
      taxAmount: 30.0,
      total: 230.0,
      paymentMethod: PaymentMethod.cash,
      status: SaleStatus.pending,
      createdAt: DateTime(2025, 1, 1),
    );

    test('crear instancia correctamente', () {
      expect(sale.id, 'SALE-001');
      expect(sale.saleNumber, 'VTA-000001');
      expect(sale.items, hasLength(1));
      expect(sale.subtotal, 200.0);
      expect(sale.taxAmount, 30.0);
      expect(sale.total, 230.0);
      expect(sale.paymentMethod, PaymentMethod.cash);
      expect(sale.status, SaleStatus.pending);
      expect(sale.observations, '');
      expect(sale.customerName, '');
      expect(sale.customerEmail, '');
    });

    test('taxRate calcula correctamente', () {
      expect(sale.taxRate, 15.0);
    });

    test('taxRate retorna 0 cuando taxAmount es 0', () {
      final noTax = sale.copyWith(taxAmount: 0);
      expect(noTax.taxRate, 0);
    });

    test('isPending retorna true para estado pending', () {
      expect(sale.isPending, true);
      expect(sale.isCompleted, false);
      expect(sale.isCancelled, false);
    });

    test('isCompleted retorna true para estado completed', () {
      final completed = sale.copyWith(status: SaleStatus.completed);
      expect(completed.isCompleted, true);
      expect(completed.isPending, false);
    });

    test('isCancelled retorna true para estado cancelled', () {
      final cancelled = sale.copyWith(status: SaleStatus.cancelled);
      expect(cancelled.isCancelled, true);
    });

    test('copyWith modifica campos correctamente', () {
      final copy = sale.copyWith(
        observations: 'Nota',
        customerName: 'Cliente',
        customerEmail: 'cliente@test.com',
      );
      expect(copy.observations, 'Nota');
      expect(copy.customerName, 'Cliente');
      expect(copy.customerEmail, 'cliente@test.com');
      expect(copy.id, 'SALE-001');
    });

    test('toMap serializa correctamente', () {
      final map = sale.toMap();
      expect(map['id'], 'SALE-001');
      expect(map['saleNumber'], 'VTA-000001');
      expect(map['items'], isA<List>());
      expect(map['subtotal'], 200.0);
      expect(map['taxAmount'], 30.0);
      expect(map['total'], 230.0);
      expect(map['paymentMethod'], 'cash');
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<String>());
    });

    test('fromMap deserializa correctamente', () {
      final map = {
        'id': 'SALE-002',
        'saleNumber': 'VTA-000002',
        'items': [
          {
            'id': 'ITEM-002',
            'product': {
              'id': 'PROD-001',
              'sku': 'SKU-001',
              'name': 'Product',
              'price': 50.0,
              'stock': 10,
              'category': 'Cat',
              'location': 'A1',
              'status': 'active',
            },
            'quantity': 1,
            'unitPrice': 50.0,
          },
        ],
        'subtotal': '50.0',
        'taxAmount': '7.5',
        'total': '57.5',
        'paymentMethod': 'card',
        'status': 'completed',
        'createdAt': '2025-06-01T10:00:00.000',
        'observations': 'Obs',
        'customerName': 'Juan',
        'customerEmail': 'juan@test.com',
      };
      final s = Sale.fromMap(map);
      expect(s.id, 'SALE-002');
      expect(s.saleNumber, 'VTA-000002');
      expect(s.items, hasLength(1));
      expect(s.subtotal, 50.0);
      expect(s.taxAmount, 7.5);
      expect(s.total, 57.5);
      expect(s.paymentMethod, PaymentMethod.card);
      expect(s.status, SaleStatus.completed);
      expect(s.observations, 'Obs');
      expect(s.customerName, 'Juan');
      expect(s.customerEmail, 'juan@test.com');
    });

    test('fromMap usa valores por defecto para campos opcionales', () {
      final map = {
        'id': 'SALE-003',
        'saleNumber': 'VTA-000003',
        'items': [],
        'subtotal': '0',
        'taxAmount': '0',
        'total': '0',
        'paymentMethod': 'unknown_method',
        'status': 'unknown_status',
        'createdAt': '2025-01-01T00:00:00.000',
      };
      final s = Sale.fromMap(map);
      expect(s.paymentMethod, PaymentMethod.other);
      expect(s.status, SaleStatus.pending);
      expect(s.observations, '');
      expect(s.customerName, '');
      expect(s.customerEmail, '');
    });
  });

  group('SaleStatus', () {
    test('tiene 3 valores', () {
      expect(SaleStatus.values, hasLength(3));
      expect(SaleStatus.values, containsAll([SaleStatus.pending, SaleStatus.completed, SaleStatus.cancelled]));
    });
  });

  group('PaymentMethod', () {
    test('tiene 4 valores', () {
      expect(PaymentMethod.values, hasLength(4));
      expect(PaymentMethod.values, containsAll([PaymentMethod.cash, PaymentMethod.card, PaymentMethod.transfer, PaymentMethod.other]));
    });
  });
}
