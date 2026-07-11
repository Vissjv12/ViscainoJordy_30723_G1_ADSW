import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/stock_alert.dart';
import 'package:paperboost/logic/validators/stock_alert_validator.dart';

void main() {
  group('StockAlertValidator Tests', () {
    test('Validar alerta correcta no retorna errores', () {
      const alert = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-001',
        minimumQuantity: 10,
        isActive: true,
      );

      final errors = StockAlertValidator.validate(alert);

      expect(errors, isEmpty);
    });

    test('Validar alerta con producto vacío retorna error', () {
      const alert = StockAlert(
        id: 'ALERT-001',
        productId: '  ',
        minimumQuantity: 10,
        isActive: true,
      );

      final errors = StockAlertValidator.validate(alert);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('producto es obligatorio'));
    });

    test('Validar alerta con cantidad mínima negativa retorna error', () {
      const alert = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-001',
        minimumQuantity: -5,
        isActive: true,
      );

      final errors = StockAlertValidator.validate(alert);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('no puede ser negativa'));
    });

    test('se puede instanciar el constructor privado', () {
      expect(StockAlertValidator(), isA<StockAlertValidator>());
    });
  });
}
