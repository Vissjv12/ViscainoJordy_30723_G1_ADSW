import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/stock_alert.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_stock_alert_repository.dart';
import 'package:paperboost/data/repositories/stock_alert_repository.dart';
import 'package:paperboost/logic/services/stock_alert_service.dart';

void main() {
  group('StockAlertService Tests', () {
    late StockAlertService service;
    late InMemoryStockAlertRepository alertRepository;
    late InMemoryProductRepository productRepository;
    late Product testProduct;

    setUp(() async {
      alertRepository = InMemoryStockAlertRepository();
      productRepository = InMemoryProductRepository();

      testProduct = const Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 5,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(testProduct);

      service = StockAlertService(
        stockAlertRepository: alertRepository,
        productRepository: productRepository,
      );
    });

    test('Crear alerta exitosamente', () async {
      final result = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.productId, 'PROD-001');
      expect(result.data!.minimumQuantity, 10);
      expect(result.data!.isActive, true);
    });

    test('Fallar al crear alerta para producto inexistente', () async {
      final result = await service.createAlert(
        productId: 'PROD-NONEXISTENT',
        minimumQuantity: 10,
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('no existe'));
    });

    test('Fallar al crear alerta duplicada para el mismo producto', () async {
      await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final result = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 5,
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Ya existe una alerta'));
    });

    test('Actualizar alerta exitosamente', () async {
      final registerResult = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final alertId = registerResult.data!.id;

      final updateResult = await service.updateAlert(
        id: alertId,
        minimumQuantity: 15,
        isActive: false,
      );

      expect(updateResult.isSuccess, true);
      expect(updateResult.data!.minimumQuantity, 15);
      expect(updateResult.data!.isActive, false);
    });

    test('Cambiar estado (toggle) de alerta', () async {
      final registerResult = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final alertId = registerResult.data!.id;

      final toggle1 = await service.toggleAlertStatus(alertId);
      expect(toggle1.isSuccess, true);
      expect(toggle1.data!.isActive, false);

      final toggle2 = await service.toggleAlertStatus(alertId);
      expect(toggle2.isSuccess, true);
      expect(toggle2.data!.isActive, true);
    });

    test('Obtener alertas disparadas (triggered)', () async {
      // testProduct tiene stock = 5.
      // Creamos alerta activa con mínimo 10 (debería dispararse)
      await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final triggeredResult = await service.getTriggeredAlerts();

      expect(triggeredResult.isSuccess, true);
      expect(triggeredResult.data!.length, 1);
      expect(triggeredResult.data!.first.productId, 'PROD-001');

      // Creamos otro producto con stock 20 y alerta 5 (no debería dispararse)
      const p2 = Product(
        id: 'PROD-002',
        sku: 'SKU-002',
        name: 'Product 2',
        price: 50.0,
        stock: 20,
        category: 'Test',
        location: 'A2',
      );
      await productRepository.save(p2);
      await service.createAlert(
        productId: 'PROD-002',
        minimumQuantity: 5,
      );

      final triggeredResult2 = await service.getTriggeredAlerts();
      expect(triggeredResult2.data!.length, 1); // Sigue siendo sólo el primero
    });

    test('Fallar al crear alerta con cantidad mínima inválida', () async {
      final result = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: -1,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('cantidad mínima no puede ser negativa'));
    });

    test('Fallar al actualizar alerta con datos inválidos', () async {
      final registerResult = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final updateResult = await service.updateAlert(
        id: registerResult.data!.id,
        minimumQuantity: -1,
        isActive: true,
      );
      expect(updateResult.isSuccess, false);
      expect(updateResult.message, contains('cantidad mínima no puede ser negativa'));
    });
  });

  group('StockAlertService - Catch blocks', () {
    late Product testProduct;

    setUp(() async {
      testProduct = const Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 5,
        category: 'Test',
        location: 'A1',
      );
    });

    test('createAlert maneja error del repositorio', () async {
      final productRepo = InMemoryProductRepository();
      await productRepo.save(testProduct);
      final throwingRepo = _ThrowingStockAlertRepository();
      final service = StockAlertService(
        stockAlertRepository: throwingRepo,
        productRepository: productRepo,
      );

      final result = await service.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('Error al registrar la alerta'));
    });

    test('updateAlert maneja error del repositorio', () async {
      final productRepo = InMemoryProductRepository();
      await productRepo.save(testProduct);
      final alertRepo = InMemoryStockAlertRepository();

      final baseService = StockAlertService(
        stockAlertRepository: alertRepo,
        productRepository: productRepo,
      );
      final created = await baseService.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final throwingRepo = _ThrowingStockAlertRepository(
        alertToFind: created.data,
      );
      final service = StockAlertService(
        stockAlertRepository: throwingRepo,
        productRepository: productRepo,
      );

      final result = await service.updateAlert(
        id: created.data!.id,
        minimumQuantity: 15,
        isActive: false,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('Error al actualizar la alerta'));
    });

    test('toggleAlertStatus maneja error del repositorio', () async {
      final productRepo = InMemoryProductRepository();
      await productRepo.save(testProduct);
      final alertRepo = InMemoryStockAlertRepository();

      final baseService = StockAlertService(
        stockAlertRepository: alertRepo,
        productRepository: productRepo,
      );
      final created = await baseService.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      final throwingRepo = _ThrowingStockAlertRepository(
        alertToFind: created.data,
      );
      final service = StockAlertService(
        stockAlertRepository: throwingRepo,
        productRepository: productRepo,
      );

      final result = await service.toggleAlertStatus(created.data!.id);
      expect(result.isSuccess, false);
      expect(result.message, contains('Error al cambiar estado de la alerta'));
    });

    test('getAlerts maneja error del repositorio', () async {
      final productRepo = InMemoryProductRepository();
      final throwingRepo = _ThrowingStockAlertRepository();
      final service = StockAlertService(
        stockAlertRepository: throwingRepo,
        productRepository: productRepo,
      );

      final result = await service.getAlerts();
      expect(result.isSuccess, false);
      expect(result.message, contains('Error al consultar alertas'));
    });

    test('getAlertByProductId maneja error del repositorio', () async {
      final productRepo = InMemoryProductRepository();
      final throwingRepo = _ThrowingStockAlertRepository(
        throwOnFindByProductId: true,
      );
      final service = StockAlertService(
        stockAlertRepository: throwingRepo,
        productRepository: productRepo,
      );

      final result = await service.getAlertByProductId('PROD-001');
      expect(result.isSuccess, false);
      expect(result.message, contains('Error al consultar la alerta del producto'));
    });

    test('getTriggeredAlerts maneja error del repositorio', () async {
      final productRepo = InMemoryProductRepository();
      final throwingRepo = _ThrowingStockAlertRepository();
      final service = StockAlertService(
        stockAlertRepository: throwingRepo,
        productRepository: productRepo,
      );

      final result = await service.getTriggeredAlerts();
      expect(result.isSuccess, false);
      expect(result.message, contains('Error al consultar alertas activadas'));
    });
  });
}

class _ThrowingStockAlertRepository implements StockAlertRepository {
  final StockAlert? alertToFind;
  final bool throwOnFindByProductId;

  _ThrowingStockAlertRepository({
    this.alertToFind,
    this.throwOnFindByProductId = false,
  });

  @override
  Future<List<StockAlert>> findAll() async {
    throw Exception('Simulated error');
  }

  @override
  Future<StockAlert?> findById(String id) async => alertToFind;

  @override
  Future<StockAlert?> findByProductId(String productId) async {
    if (throwOnFindByProductId) throw Exception('Simulated error');
    return null;
  }

  @override
  Future<void> save(StockAlert alert) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> update(StockAlert alert) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> delete(String id) async {
    throw Exception('Simulated error');
  }
}
