import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/stock_alert.dart';
import 'package:paperboost/data/repositories/in_memory_stock_alert_repository.dart';

void main() {
  group('InMemoryStockAlertRepository Tests', () {
    late InMemoryStockAlertRepository repository;

    setUp(() {
      repository = InMemoryStockAlertRepository();
    });

    test('Guardar y buscar alerta por ID y producto', () async {
      const alert = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-001',
        minimumQuantity: 10,
        isActive: true,
      );

      await repository.save(alert);

      final foundById = await repository.findById('ALERT-001');
      final foundByProduct = await repository.findByProductId('PROD-001');
      final all = await repository.findAll();

      expect(foundById, isNotNull);
      expect(foundById!.minimumQuantity, 10);
      expect(foundByProduct, isNotNull);
      expect(foundByProduct!.id, 'ALERT-001');
      expect(all.length, 1);
    });

    test('No permitir guardar alerta duplicada por ID o producto', () async {
      const alert1 = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      await repository.save(alert1);

      // Duplicado por ID
      const alert2 = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-002',
        minimumQuantity: 5,
      );

      expect(() => repository.save(alert2), throwsStateError);

      // Duplicado por producto
      const alert3 = StockAlert(
        id: 'ALERT-003',
        productId: 'PROD-001',
        minimumQuantity: 20,
      );

      expect(() => repository.save(alert3), throwsStateError);
    });

    test('Actualizar alerta correctamente', () async {
      const alert = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-001',
        minimumQuantity: 10,
        isActive: true,
      );

      await repository.save(alert);

      final updated = alert.copyWith(minimumQuantity: 15, isActive: false);
      await repository.update(updated);

      final found = await repository.findById('ALERT-001');
      expect(found!.minimumQuantity, 15);
      expect(found.isActive, false);
    });

    test('Eliminar alerta correctamente', () async {
      const alert = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-001',
        minimumQuantity: 10,
      );

      await repository.save(alert);
      expect((await repository.findAll()).length, 1);

      await repository.delete('ALERT-001');
      expect((await repository.findAll()).length, 0);
    });

    test('Actualizar alerta inexistente lanza StateError', () async {
      const nonExistent = StockAlert(
        id: 'ALERT-999',
        productId: 'PROD-999',
        minimumQuantity: 5,
      );

      expect(
        () => repository.update(nonExistent),
        throwsStateError,
      );
    });
  });
}
