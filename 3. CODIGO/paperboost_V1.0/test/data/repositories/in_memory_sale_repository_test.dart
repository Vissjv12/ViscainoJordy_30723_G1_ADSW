import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale.dart';
import 'package:paperboost/data/models/sale_item.dart';
import 'package:paperboost/data/repositories/in_memory_sale_repository.dart';

void main() {
  group('InMemorySaleRepository - Operaciones Básicas', () {
    late InMemorySaleRepository repository;
    late Sale testSale;

    setUp(() async {
      repository = InMemorySaleRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      testSale = Sale(
        id: 'SALE-001',
        saleNumber: 'VTA-000001',
        items: [
          SaleItem(
            id: 'ITEM-001',
            product: product,
            quantity: 2,
            unitPrice: 100.0,
          ),
        ],
        subtotal: 200.0,
        taxAmount: 38.0,
        total: 238.0,
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.completed,
        createdAt: DateTime.now(),
      );
    });

    test('Guardar venta correctamente', () async {
      await repository.save(testSale);
      final sales = await repository.findAll(
        includeCompleted: true,
        includeCancelled: true,
      );

      expect(sales.length, 1);
      expect(sales.first.id, 'SALE-001');
    });

    test('Obtener venta por ID', () async {
      await repository.save(testSale);
      final sale = await repository.findById('SALE-001');

      expect(sale, isNotNull);
      expect(sale!.saleNumber, 'VTA-000001');
    });

    test('Obtener venta por número', () async {
      await repository.save(testSale);
      final sale = await repository.findBySaleNumber('VTA-000001');

      expect(sale, isNotNull);
      expect(sale!.id, 'SALE-001');
    });

    test('Lanzar error al guardar venta duplicada', () async {
      await repository.save(testSale);

      expect(
        () => repository.save(testSale),
        throwsA(isA<StateError>()),
      );
    });

    test('Actualizar venta', () async {
      await repository.save(testSale);

      final updatedSale =
          testSale.copyWith(observations: 'Test observation');

      await repository.update(updatedSale);

      final retrievedSale = await repository.findById('SALE-001');

      expect(retrievedSale!.observations, 'Test observation');
    });

    test('Lanzar error al actualizar venta inexistente', () async {
      expect(
        () => repository.update(testSale),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('InMemorySaleRepository - Filtros', () {
    late InMemorySaleRepository repository;

    setUp(() async {
      repository = InMemorySaleRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      final completedSale = Sale(
        id: 'SALE-001',
        saleNumber: 'VTA-000001',
        items: [
          SaleItem(
            id: 'ITEM-001',
            product: product,
            quantity: 1,
            unitPrice: 100.0,
          ),
        ],
        subtotal: 100.0,
        taxAmount: 19.0,
        total: 119.0,
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.completed,
        createdAt: DateTime.now(),
      );

      final cancelledSale = Sale(
        id: 'SALE-002',
        saleNumber: 'VTA-000002',
        items: [
          SaleItem(
            id: 'ITEM-002',
            product: product,
            quantity: 1,
            unitPrice: 100.0,
          ),
        ],
        subtotal: 100.0,
        taxAmount: 19.0,
        total: 119.0,
        paymentMethod: PaymentMethod.card,
        status: SaleStatus.cancelled,
        createdAt: DateTime.now(),
      );

      await repository.save(completedSale);
      await repository.save(cancelledSale);
    });

    test('Excluir ventas completadas por defecto', () async {
      final sales = await repository.findAll();

      expect(sales.isEmpty, true);
    });

    test('Incluir ventas completadas', () async {
      final sales = await repository.findAll(includeCompleted: true);

      expect(
        sales.any((s) => s.status == SaleStatus.completed),
        true,
      );
    });

    test('Excluir ventas canceladas por defecto', () async {
      final sales = await repository.findAll(includeCompleted: true);

      expect(
        sales.any((s) => s.status == SaleStatus.cancelled),
        false,
      );
    });

    test('Incluir ventas canceladas', () async {
      final sales = await repository.findAll(
        includeCompleted: true,
        includeCancelled: true,
      );

      expect(sales.length, 2);
    });
  });

  group('InMemorySaleRepository - Numeración de Ventas', () {
    late InMemorySaleRepository repository;

    setUp(() {
      repository = InMemorySaleRepository();
    });

    test('Incrementar número de venta secuencialmente', () async {
      final num1 = await repository.getNextSaleNumber();
      final num2 = await repository.getNextSaleNumber();
      final num3 = await repository.getNextSaleNumber();

      expect(num1, 1);
      expect(num2, 2);
      expect(num3, 3);
    });
  });

  group('InMemorySaleRepository - Cancelación', () {
    late InMemorySaleRepository repository;
    late Sale testSale;

    setUp(() async {
      repository = InMemorySaleRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      testSale = Sale(
        id: 'SALE-001',
        saleNumber: 'VTA-000001',
        items: [
          SaleItem(
            id: 'ITEM-001',
            product: product,
            quantity: 1,
            unitPrice: 100.0,
          ),
        ],
        subtotal: 100.0,
        taxAmount: 19.0,
        total: 119.0,
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.pending,
        createdAt: DateTime.now(),
      );

      await repository.save(testSale);
    });

    test('Cancelar venta correctamente', () async {
      await repository.cancel('SALE-001');
      final sale = await repository.findById('SALE-001');

      expect(sale!.status, SaleStatus.cancelled);
    });

    test('Lanzar error al cancelar venta inexistente', () async {
      expect(
        () => repository.cancel('SALE-999'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
