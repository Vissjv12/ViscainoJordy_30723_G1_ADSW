import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/logic/validators/product_validator.dart';

void main() {
  group('ProductValidator', () {
    const validProduct = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Producto Válido',
      price: 100.0,
      stock: 50,
      category: 'Papelería',
      location: 'A1',
    );

    test('retorna lista vacía para producto válido', () {
      final errors = ProductValidator.validateProduct(validProduct);
      expect(errors, isEmpty);
    });

    test('detecta SKU vacío', () {
      final product = validProduct.copyWith(sku: '  ');
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('El SKU es obligatorio.'));
    });

    test('detecta nombre vacío', () {
      final product = validProduct.copyWith(name: '');
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('El nombre del producto es obligatorio.'));
    });

    test('detecta precio cero', () {
      final product = validProduct.copyWith(price: 0);
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('El precio debe ser mayor que cero.'));
    });

    test('detecta precio negativo', () {
      final product = validProduct.copyWith(price: -10);
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('El precio debe ser mayor que cero.'));
    });

    test('detecta stock negativo', () {
      final product = validProduct.copyWith(stock: -1);
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('El stock no puede ser negativo.'));
    });

    test('permite stock cero', () {
      final product = validProduct.copyWith(stock: 0);
      final errors = ProductValidator.validateProduct(product);
      expect(errors, isNot(contains('El stock no puede ser negativo.')));
    });

    test('detecta categoría vacía', () {
      final product = validProduct.copyWith(category: '');
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('La categoría es obligatoria.'));
    });

    test('detecta ubicación vacía', () {
      final product = validProduct.copyWith(location: '  ');
      final errors = ProductValidator.validateProduct(product);
      expect(errors, contains('La ubicación es obligatoria.'));
    });

    test('acumula múltiples errores', () {
      final product = validProduct.copyWith(
        sku: '',
        name: '',
        price: -1,
        stock: -5,
        category: '',
        location: '',
      );
      final errors = ProductValidator.validateProduct(product);
      expect(errors, hasLength(6));
    });

    test('se puede instanciar el constructor privado', () {
      expect(ProductValidator(), isA<ProductValidator>());
    });
  });
}
