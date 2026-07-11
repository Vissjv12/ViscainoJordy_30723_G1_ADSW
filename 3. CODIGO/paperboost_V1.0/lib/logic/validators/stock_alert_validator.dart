import '../../data/models/stock_alert.dart';

class StockAlertValidator {
  const StockAlertValidator();

  static List<String> validate(StockAlert alert) {
    final errors = <String>[];

    if (alert.productId.trim().isEmpty) {
      errors.add('El producto es obligatorio.');
    }

    if (alert.minimumQuantity < 0) {
      errors.add('La cantidad mínima no puede ser negativa.');
    }

    return errors;
  }
}
