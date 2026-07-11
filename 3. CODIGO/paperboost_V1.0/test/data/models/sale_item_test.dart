import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale_item.dart';

void main() {
  group('SaleItem', () {
    const product = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Test Product',
      price: 100.0,
      stock: 50,
      category: 'Test',
      location: 'A1',
    );

    const item = SaleItem(
      id: 'ITEM-001',
      product: product,
      quantity: 3,
      unitPrice: 150.0,
    );

    test('crear instancia correctamente', () {
      expect(item.id, 'ITEM-001');
      expect(item.product.id, 'PROD-001');
      expect(item.quantity, 3);
      expect(item.unitPrice, 150.0);
    });

    test('subtotal calcula correctamente', () {
      expect(item.subtotal, 450.0);
    });

    test('subtotal con cantidad 0', () {
      const zeroItem = SaleItem(
        id: 'ITEM-002',
        product: product,
        quantity: 0,
        unitPrice: 100.0,
      );
      expect(zeroItem.subtotal, 0);
    });

    test('copyWith modifica campos correctamente', () {
      final copy = item.copyWith(quantity: 5, unitPrice: 200.0);
      expect(copy.id, 'ITEM-001');
      expect(copy.quantity, 5);
      expect(copy.unitPrice, 200.0);
      expect(copy.subtotal, 1000.0);
    });

    test('toMap serializa correctamente', () {
      final map = item.toMap();
      expect(map['id'], 'ITEM-001');
      expect(map['product'], isA<Map<String, dynamic>>());
      expect(map['quantity'], 3);
      expect(map['unitPrice'], 150.0);
    });

    test('fromMap deserializa correctamente', () {
      final map = {
        'id': 'ITEM-003',
        'product': {
          'id': 'PROD-002',
          'sku': 'SKU-002',
          'name': 'Other',
          'price': 25.0,
          'stock': 5,
          'category': 'Cat',
          'location': 'B2',
          'status': 'active',
        },
        'quantity': '2',
        'unitPrice': '25.0',
      };
      final si = SaleItem.fromMap(map);
      expect(si.id, 'ITEM-003');
      expect(si.product.id, 'PROD-002');
      expect(si.quantity, 2);
      expect(si.unitPrice, 25.0);
      expect(si.subtotal, 50.0);
    });

    test('copyWith sin parámetros conserva todos los valores', () {
      final copy = item.copyWith();
      expect(copy.id, item.id);
      expect(copy.quantity, item.quantity);
      expect(copy.unitPrice, item.unitPrice);
      expect(copy.product.id, item.product.id);
    });
  });
}
