import '../../data/models/sale_item.dart';

class SaleValidator {
  const SaleValidator();

  static List<String> validateSaleItems(List<SaleItem> items) {
    final errors = <String>[];

    if (items.isEmpty) {
      errors.add('Debe agregar al menos un producto a la venta.');
      return errors;
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemErrors = _validateSaleItem(item, i + 1);
      errors.addAll(itemErrors);
    }

    return errors;
  }

  static List<String> _validateSaleItem(
    SaleItem item,
    int itemIndex,
  ) {
    final errors = <String>[];

    if (item.quantity <= 0) {
      errors.add(
        'Producto $itemIndex: La cantidad debe ser mayor que cero.',
      );
    }

    if (item.unitPrice < 0) {
      errors.add(
        'Producto $itemIndex: El precio unitario no puede ser negativo.',
      );
    }

    return errors;
  }

  static List<String> validateStockAvailability(
    SaleItem item,
  ) {
    final errors = <String>[];

    if (item.quantity > item.product.stock) {
      errors.add(
        'Stock insuficiente para "${item.product.name}". '
        'Disponible: ${item.product.stock}, Solicitado: ${item.quantity}',
      );
    }

    return errors;
  }

  static List<String> validateStockForAllItems(
    List<SaleItem> items,
  ) {
    final errors = <String>[];

    for (final item in items) {
      final stockErrors = validateStockAvailability(item);
      errors.addAll(stockErrors);
    }

    return errors;
  }

  static List<String> validatePaymentMethod(
    String? paymentMethodName,
  ) {
    final errors = <String>[];

    if (paymentMethodName == null || paymentMethodName.trim().isEmpty) {
      errors.add('Debe seleccionar un método de pago.');
    }

    return errors;
  }

  static List<String> validateCustomerInfo(
    String? customerName,
    String? customerEmail,
  ) {
    final errors = <String>[];

    if (customerName != null &&
        customerName.isNotEmpty &&
        customerName.trim().length < 3) {
      errors.add('El nombre del cliente debe tener al menos 3 caracteres.');
    }

    if (customerEmail != null && customerEmail.isNotEmpty) {
      if (!_isValidEmail(customerEmail)) {
        errors.add('Ingrese un correo electrónico válido.');
      }
    }

    return errors;
  }

  static bool _isValidEmail(String email) {
    final emailExpression = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailExpression.hasMatch(email);
  }
}
