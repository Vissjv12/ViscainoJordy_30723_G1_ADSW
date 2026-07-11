import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';

void main() {
  group('Product', () {
    const product = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Test Product',
      price: 100.0,
      stock: 50,
      category: 'Test',
      location: 'A1',
    );

    test('crear instancia correctamente', () {
      expect(product.id, 'PROD-001');
      expect(product.sku, 'SKU-001');
      expect(product.name, 'Test Product');
      expect(product.price, 100.0);
      expect(product.stock, 50);
      expect(product.category, 'Test');
      expect(product.location, 'A1');
      expect(product.status, ProductStatus.active);
    });

    test('isActive retorna true para estado active', () {
      expect(product.isActive, true);
    });

    test('isActive retorna false para estado inactive', () {
      const inactive = Product(
        id: 'PROD-002',
        sku: 'SKU-002',
        name: 'Inactive',
        price: 10.0,
        stock: 0,
        category: 'Test',
        location: 'A2',
        status: ProductStatus.inactive,
      );
      expect(inactive.isActive, false);
    });

    test('copyWith modifica campos correctamente', () {
      final copy = product.copyWith(name: 'Updated', price: 200.0);
      expect(copy.id, 'PROD-001');
      expect(copy.name, 'Updated');
      expect(copy.price, 200.0);
      expect(copy.stock, 50);
    });

    test('copyWith sin argumentos retorna copia idéntica', () {
      final copy = product.copyWith();
      expect(copy.id, product.id);
      expect(copy.sku, product.sku);
      expect(copy.name, product.name);
    });

    test('toMap serializa correctamente', () {
      final map = product.toMap();
      expect(map['id'], 'PROD-001');
      expect(map['sku'], 'SKU-001');
      expect(map['name'], 'Test Product');
      expect(map['price'], 100.0);
      expect(map['stock'], 50);
      expect(map['category'], 'Test');
      expect(map['location'], 'A1');
      expect(map['status'], 'active');
    });

    test('fromMap deserializa correctamente', () {
      final map = {
        'id': 'PROD-003',
        'sku': 'SKU-003',
        'name': 'From Map',
        'price': 75.5,
        'stock': 10,
        'category': 'Cat',
        'location': 'B2',
        'status': 'active',
      };
      final p = Product.fromMap(map);
      expect(p.id, 'PROD-003');
      expect(p.price, 75.5);
      expect(p.stock, 10);
      expect(p.status, ProductStatus.active);
    });

    test('fromMap usa default active si status es inválido', () {
      final map = {
        'id': 'PROD-004',
        'sku': 'SKU-004',
        'name': 'Bad Status',
        'price': 10.0,
        'stock': 1,
        'category': 'Cat',
        'location': 'C3',
        'status': 'unknown_status',
      };
      final p = Product.fromMap(map);
      expect(p.status, ProductStatus.active);
    });

    test('fromMap maneja price como int', () {
      final map = {
        'id': 'PROD-005',
        'sku': 'SKU-005',
        'name': 'Int Price',
        'price': 99,
        'stock': 5,
        'category': 'Cat',
        'location': 'D4',
        'status': 'active',
      };
      final p = Product.fromMap(map);
      expect(p.price, 99.0);
    });

    test('fromMap maneja price como string', () {
      final map = {
        'id': 'PROD-006',
        'sku': 'SKU-006',
        'name': 'String Price',
        'price': '50.0',
        'stock': 3,
        'category': 'Cat',
        'location': 'E5',
        'status': 'active',
      };
      final p = Product.fromMap(map);
      expect(p.price, 50.0);
    });

    test('fromMap usa 0 para price inválido', () {
      final map = {
        'id': 'PROD-007',
        'sku': 'SKU-007',
        'name': 'Bad Price',
        'price': 'not-a-number',
        'stock': 3,
        'category': 'Cat',
        'location': 'E5',
        'status': 'active',
      };
      final p = Product.fromMap(map);
      expect(p.price, 0);
    });

    test('fromMap maneja stock como string', () {
      final map = {
        'id': 'PROD-008',
        'sku': 'SKU-008',
        'name': 'String Stock',
        'price': 10.0,
        'stock': '25',
        'category': 'Cat',
        'location': 'F6',
        'status': 'active',
      };
      final p = Product.fromMap(map);
      expect(p.stock, 25);
    });

    test('fromMap usa 0 para stock inválido', () {
      final map = {
        'id': 'PROD-009',
        'sku': 'SKU-009',
        'name': 'Bad Stock',
        'price': 10.0,
        'stock': 'invalid',
        'category': 'Cat',
        'location': 'F6',
        'status': 'active',
      };
      final p = Product.fromMap(map);
      expect(p.stock, 0);
    });

    test('toString contiene información del producto', () {
      final str = product.toString();
      expect(str, contains('PROD-001'));
      expect(str, contains('SKU-001'));
      expect(str, contains('Test Product'));
    });
  });

  group('ProductStatus', () {
    test('tiene valores active e inactive', () {
      expect(ProductStatus.values, hasLength(2));
      expect(ProductStatus.active, isA<ProductStatus>());
      expect(ProductStatus.inactive, isA<ProductStatus>());
    });
  });
}
