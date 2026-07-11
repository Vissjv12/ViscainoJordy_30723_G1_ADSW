import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale_item.dart';
import 'package:paperboost/logic/validators/sale_validator.dart';

void main() {
  group('SaleValidator - Validación de Items de Venta', () {
    late Product testProduct;

    setUp(() {
      testProduct = const Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Producto Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );
    });

    test('Validar que lista vacía retorna error', () {
      final errors = SaleValidator.validateSaleItems([]);

      expect(
        errors,
        contains('Debe agregar al menos un producto a la venta.'),
      );
    });

    test('Validar cantidad válida no retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 5,
        unitPrice: 100.0,
      );

      final errors = SaleValidator.validateSaleItems([item]);

      expect(errors, isEmpty);
    });

    test('Validar cantidad cero retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 0,
        unitPrice: 100.0,
      );

      final errors = SaleValidator.validateSaleItems([item]);

      expect(errors.any((e) => e.contains('La cantidad debe ser mayor que cero')), isTrue);
    });

    test('Validar cantidad negativa retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: -5,
        unitPrice: 100.0,
      );

      final errors = SaleValidator.validateSaleItems([item]);

      expect(errors.any((e) => e.contains('La cantidad debe ser mayor que cero')), isTrue);
    });

    test('Validar precio unitario negativo retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 5,
        unitPrice: -10.0,
      );

      final errors = SaleValidator.validateSaleItems([item]);

      expect(errors.any((e) => e.contains('El precio unitario no puede ser negativo')), isTrue);
    });
  });

  group('SaleValidator - Validación de Stock', () {
    late Product productWithStock;
    late Product productSinStock;

    setUp(() {
      productWithStock = const Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Producto Con Stock',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      productSinStock = const Product(
        id: 'PROD-002',
        sku: 'SKU-002',
        name: 'Producto Sin Stock',
        price: 50.0,
        stock: 0,
        category: 'Test',
        location: 'A2',
      );
    });

    test('Stock suficiente no retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: productWithStock,
        quantity: 5,
        unitPrice: 100.0,
      );

      final errors = SaleValidator.validateStockAvailability(item);

      expect(errors, isEmpty);
    });

    test('Stock exacto no retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: productWithStock,
        quantity: 10,
        unitPrice: 100.0,
      );

      final errors = SaleValidator.validateStockAvailability(item);

      expect(errors, isEmpty);
    });

    test('Stock insuficiente retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: productWithStock,
        quantity: 15,
        unitPrice: 100.0,
      );

      final errors = SaleValidator.validateStockAvailability(item);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('Stock insuficiente'));
    });

    test('Stock cero retorna error', () {
      final item = SaleItem(
        id: 'ITEM-001',
        product: productSinStock,
        quantity: 1,
        unitPrice: 50.0,
      );

      final errors = SaleValidator.validateStockAvailability(item);

      expect(errors, isNotEmpty);
    });

    test('Validar múltiples items verifica stock para cada uno', () {
      final item1 = SaleItem(
        id: 'ITEM-001',
        product: productWithStock,
        quantity: 15,
        unitPrice: 100.0,
      );

      final item2 = SaleItem(
        id: 'ITEM-002',
        product: productSinStock,
        quantity: 1,
        unitPrice: 50.0,
      );

      final errors = SaleValidator.validateStockForAllItems([item1, item2]);

      expect(errors.length, 2);
    });
  });

  group('SaleValidator - Validación de Información de Cliente', () {
    test('Cliente válido no retorna error', () {
      final errors = SaleValidator.validateCustomerInfo(
        'Juan Pérez',
        'juan@example.com',
      );

      expect(errors, isEmpty);
    });

    test('Cliente sin información no retorna error', () {
      final errors = SaleValidator.validateCustomerInfo(null, null);

      expect(errors, isEmpty);
    });

    test('Nombre muy corto retorna error', () {
      final errors = SaleValidator.validateCustomerInfo(
        'JJ',
        'juan@example.com',
      );

      expect(errors, anyElement(contains('debe tener al menos 3 caracteres')));
    });

    test('Email inválido retorna error', () {
      final errors = SaleValidator.validateCustomerInfo(
        'Juan Pérez',
        'correo-invalido',
      );

      expect(errors, anyElement(contains('correo electrónico válido')));
    });

    test('Email válido no retorna error', () {
      final errors = SaleValidator.validateCustomerInfo(
        'Juan Pérez',
        'juan.perez@empresa.com.co',
      );

      expect(errors, isEmpty);
    });
  });

  group('SaleValidator - Validación de Método de Pago', () {
    test('Método de pago válido no retorna error', () {
      final errors = SaleValidator.validatePaymentMethod('cash');

      expect(errors, isEmpty);
    });

    test('Método de pago vacío retorna error', () {
      final errors = SaleValidator.validatePaymentMethod('');

      expect(errors, anyElement(contains('Debe seleccionar un método de pago')));
    });

    test('Método de pago null retorna error', () {
      final errors = SaleValidator.validatePaymentMethod(null);

      expect(errors, anyElement(contains('Debe seleccionar un método de pago')));
    });
  });

  group('SaleValidator - Edge Cases', () {
    test('se puede instanciar el constructor privado', () {
      expect(SaleValidator(), isA<SaleValidator>());
    });

    test('nombre corto y email inválido juntos acumulan errores', () {
      final errors = SaleValidator.validateCustomerInfo(
        'AB',
        'correo-mal',
      );
      expect(errors, anyElement(contains('debe tener al menos 3 caracteres')));
      expect(errors, anyElement(contains('correo electrónico válido')));
      expect(errors, hasLength(2));
    });
  });
}