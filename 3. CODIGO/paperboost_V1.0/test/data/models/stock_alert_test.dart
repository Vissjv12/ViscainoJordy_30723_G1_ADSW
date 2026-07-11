import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/stock_alert.dart';

void main() {
  group('StockAlert', () {
    const alert = StockAlert(
      id: 'ALERT-001',
      productId: 'PROD-001',
      minimumQuantity: 10,
    );

    test('crear instancia correctamente', () {
      expect(alert.id, 'ALERT-001');
      expect(alert.productId, 'PROD-001');
      expect(alert.minimumQuantity, 10);
      expect(alert.isActive, true);
    });

    test('isActive se puede inicializar como false', () {
      const inactive = StockAlert(
        id: 'ALERT-002',
        productId: 'PROD-002',
        minimumQuantity: 5,
        isActive: false,
      );
      expect(inactive.isActive, false);
    });

    test('copyWith modifica campos correctamente', () {
      final copy = alert.copyWith(minimumQuantity: 20, isActive: false);
      expect(copy.id, 'ALERT-001');
      expect(copy.minimumQuantity, 20);
      expect(copy.isActive, false);
      expect(copy.productId, 'PROD-001');
    });

    test('toMap serializa correctamente', () {
      final map = alert.toMap();
      expect(map['id'], 'ALERT-001');
      expect(map['productId'], 'PROD-001');
      expect(map['minimumQuantity'], 10);
      expect(map['isActive'], true);
    });

    test('fromMap deserializa correctamente', () {
      final map = {
        'id': 'ALERT-003',
        'productId': 'PROD-003',
        'minimumQuantity': '15',
        'isActive': false,
      };
      final a = StockAlert.fromMap(map);
      expect(a.id, 'ALERT-003');
      expect(a.productId, 'PROD-003');
      expect(a.minimumQuantity, 15);
      expect(a.isActive, false);
    });

    test('fromMap usa true como default para isActive', () {
      final map = {
        'id': 'ALERT-004',
        'productId': 'PROD-004',
        'minimumQuantity': '5',
      };
      final a = StockAlert.fromMap(map);
      expect(a.isActive, true);
    });

    test('toString contiene la información', () {
      final str = alert.toString();
      expect(str, contains('ALERT-001'));
      expect(str, contains('PROD-001'));
      expect(str, contains('10'));
    });

    test('copyWith sin parámetros conserva todos los valores', () {
      final copy = alert.copyWith();
      expect(copy.id, alert.id);
      expect(copy.productId, alert.productId);
      expect(copy.minimumQuantity, alert.minimumQuantity);
      expect(copy.isActive, alert.isActive);
    });

    test('copyWith con id específico usa null-coalescing en otros campos', () {
      final copy = alert.copyWith(id: 'ALERT-999');
      expect(copy.id, 'ALERT-999');
      expect(copy.productId, alert.productId);
      expect(copy.minimumQuantity, alert.minimumQuantity);
      expect(copy.isActive, alert.isActive);
    });
  });
}
