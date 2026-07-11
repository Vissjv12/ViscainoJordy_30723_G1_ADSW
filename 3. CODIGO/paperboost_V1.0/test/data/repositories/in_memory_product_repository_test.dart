import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';

void main() {
  group('InMemoryProductRepository - CRUD', () {
    late InMemoryProductRepository repository;

    setUp(() {
      repository = InMemoryProductRepository();
    });

    const product = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Test Product',
      price: 100.0,
      stock: 50,
      category: 'Test',
      location: 'A1',
    );

    test('findAll retorna lista vacía al inicio', () async {
      final products = await repository.findAll();
      expect(products, isEmpty);
    });

    test('save guarda producto correctamente', () async {
      await repository.save(product);
      final products = await repository.findAll();
      expect(products, hasLength(1));
      expect(products.first.id, 'PROD-001');
    });

    test('save ordena productos por nombre', () async {
      const productB = Product(
        id: 'PROD-002',
        sku: 'SKU-002',
        name: 'Beta',
        price: 50.0,
        stock: 10,
        category: 'Test',
        location: 'B1',
      );
      const productA = Product(
        id: 'PROD-003',
        sku: 'SKU-003',
        name: 'Alpha',
        price: 30.0,
        stock: 20,
        category: 'Test',
        location: 'A2',
      );
      await repository.save(productB);
      await repository.save(productA);
      final products = await repository.findAll();
      expect(products[0].name, 'Alpha');
      expect(products[1].name, 'Beta');
    });

    test('findById encuentra producto por ID', () async {
      await repository.save(product);
      final found = await repository.findById('PROD-001');
      expect(found, isNotNull);
      expect(found!.sku, 'SKU-001');
    });

    test('findById retorna null para ID inexistente', () async {
      final found = await repository.findById('PROD-999');
      expect(found, isNull);
    });

    test('findBySku encuentra producto por SKU', () async {
      await repository.save(product);
      final found = await repository.findBySku('SKU-001');
      expect(found, isNotNull);
      expect(found!.id, 'PROD-001');
    });

    test('findBySku normaliza SKU a mayúsculas', () async {
      await repository.save(product);
      final found = await repository.findBySku('  sku-001  ');
      expect(found, isNotNull);
    });

    test('findBySku retorna null para SKU inexistente', () async {
      final found = await repository.findBySku('SKU-999');
      expect(found, isNull);
    });

    test('existsBySku retorna true si SKU existe', () async {
      await repository.save(product);
      final exists = await repository.existsBySku('SKU-001');
      expect(exists, true);
    });

    test('existsBySku retorna false si SKU no existe', () async {
      final exists = await repository.existsBySku('SKU-999');
      expect(exists, false);
    });

    test('existsBySku excluye producto por ID', () async {
      await repository.save(product);
      final exists = await repository.existsBySku(
        'SKU-001',
        excludingProductId: 'PROD-001',
      );
      expect(exists, false);
    });

    test('save lanza error al guardar ID duplicado', () async {
      await repository.save(product);
      expect(
        () => repository.save(product),
        throwsA(isA<StateError>()),
      );
    });

    test('update modifica producto existente', () async {
      await repository.save(product);
      final updated = product.copyWith(name: 'Updated', price: 200.0);
      await repository.update(updated);
      final found = await repository.findById('PROD-001');
      expect(found!.name, 'Updated');
      expect(found.price, 200.0);
    });

    test('update lanza error si producto no existe', () async {
      expect(
        () => repository.update(product),
        throwsA(isA<StateError>()),
      );
    });

    test('deactivate cambia estado a inactive', () async {
      await repository.save(product);
      await repository.deactivate('PROD-001');
      final found = await repository.findById('PROD-001');
      expect(found!.status, ProductStatus.inactive);
      expect(found.isActive, false);
    });

    test('deactivate lanza error si ID no existe', () async {
      expect(
        () => repository.deactivate('PROD-999'),
        throwsA(isA<StateError>()),
      );
    });

    test('findAll excluye productos inactivos por defecto', () async {
      await repository.save(product);
      await repository.deactivate('PROD-001');
      final products = await repository.findAll();
      expect(products, isEmpty);
    });

    test('findAll incluye inactivos si se especifica', () async {
      await repository.save(product);
      await repository.deactivate('PROD-001');
      final products = await repository.findAll(includeInactive: true);
      expect(products, hasLength(1));
    });
  });
}
