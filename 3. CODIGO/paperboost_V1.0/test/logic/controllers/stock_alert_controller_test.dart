import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_stock_alert_repository.dart';
import 'package:paperboost/logic/controllers/stock_alert_controller.dart';
import 'package:paperboost/logic/services/stock_alert_service.dart';

void main() {
  group('StockAlertController', () {
    late StockAlertController controller;
    late InMemoryProductRepository productRepository;

    setUp(() async {
      productRepository = InMemoryProductRepository();
      final alertRepository = InMemoryStockAlertRepository();
      final alertService = StockAlertService(
        stockAlertRepository: alertRepository,
        productRepository: productRepository,
      );
      controller = StockAlertController(stockAlertService: alertService);

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Producto Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );
      await productRepository.save(product);
    });

    test('createAlert crea alerta correctamente', () async {
      final result = await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      expect(result.isSuccess, true);
      expect(result.data!.productId, 'PROD-001');
      expect(result.data!.minimumQuantity, 10);
    });

    test('createAlert rechaza producto inexistente', () async {
      final result = await controller.createAlert(
        productId: 'PROD-999',
        minimumQuantity: 5,
      );
      expect(result.isSuccess, false);
    });

    test('createAlert rechaza alerta duplicada', () async {
      await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      final result = await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 5,
      );
      expect(result.isSuccess, false);
    });

    test('updateAlert actualiza alerta', () async {
      final saved = await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      final result = await controller.updateAlert(
        id: saved.data!.id,
        minimumQuantity: 20,
        isActive: false,
      );
      expect(result.isSuccess, true);
      expect(result.data!.minimumQuantity, 20);
      expect(result.data!.isActive, false);
    });

    test('updateAlert rechaza alerta inexistente', () async {
      final result = await controller.updateAlert(
        id: 'NO-EXISTE',
        minimumQuantity: 10,
        isActive: true,
      );
      expect(result.isSuccess, false);
    });

    test('toggleAlertStatus cambia estado', () async {
      final saved = await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      expect(saved.data!.isActive, true);

      final toggled = await controller.toggleAlertStatus(saved.data!.id);
      expect(toggled.isSuccess, true);
      expect(toggled.data!.isActive, false);

      final toggledBack = await controller.toggleAlertStatus(saved.data!.id);
      expect(toggledBack.data!.isActive, true);
    });

    test('toggleAlertStatus rechaza alerta inexistente', () async {
      final result = await controller.toggleAlertStatus('NO-EXISTE');
      expect(result.isSuccess, false);
    });

    test('getAlerts retorna lista vacía al inicio', () async {
      final result = await controller.getAlerts();
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('getAlerts retorna alertas creadas', () async {
      await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      final result = await controller.getAlerts();
      expect(result.data, hasLength(1));
    });

    test('getAlertByProductId retorna alerta existente', () async {
      await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      final result = await controller.getAlertByProductId('PROD-001');
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
    });

    test('getAlertByProductId retorna null si no hay alerta', () async {
      final result = await controller.getAlertByProductId('PROD-001');
      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });

    test('getTriggeredAlerts retorna alertas activadas', () async {
      const lowStockProduct = Product(
        id: 'PROD-002',
        sku: 'SKU-002',
        name: 'Stock Bajo',
        price: 50.0,
        stock: 3,
        category: 'Test',
        location: 'A2',
      );
      await productRepository.save(lowStockProduct);

      await controller.createAlert(
        productId: 'PROD-002',
        minimumQuantity: 10,
      );

      final result = await controller.getTriggeredAlerts();
      expect(result.data, hasLength(1));
    });

    test('getTriggeredAlerts retorna vacío si no hay alertas activadas',
        () async {
      await controller.createAlert(
        productId: 'PROD-001',
        minimumQuantity: 10,
      );
      final result = await controller.getTriggeredAlerts();
      expect(result.data, isEmpty);
    });
  });
}
