import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/logic/controllers/product_controller.dart';
import 'package:paperboost/logic/services/product_service.dart';

void main() {
  group('ProductController', () {
    late ProductController productController;
    late InMemoryProductRepository repository;

    setUp(() {
      repository = InMemoryProductRepository();
      final productService = ProductService(
        productRepository: repository,
      );
      productController = ProductController(
        productService: productService,
      );
    });

    test('registerProduct delega al servicio', () async {
      final result = await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Producto Test',
        price: 50.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      expect(result.isSuccess, true);
      expect(result.data!.sku, 'SKU-001');
    });

    test('registerProduct retorna error con datos inválidos', () async {
      final result = await productController.registerProduct(
        sku: '',
        name: '',
        price: 0,
        stock: -1,
        category: '',
        location: '',
      );
      expect(result.isSuccess, false);
    });

    test('getProducts retorna lista vacía al inicio', () async {
      final result = await productController.getProducts();
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('getProducts retorna productos registrados', () async {
      await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Test',
        price: 10.0,
        stock: 5,
        category: 'Cat',
        location: 'A1',
      );
      final result = await productController.getProducts();
      expect(result.data, hasLength(1));
    });

    test('getProductById encuentra producto', () async {
      final saved = await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Test',
        price: 10.0,
        stock: 5,
        category: 'Cat',
        location: 'A1',
      );
      final result = await productController.getProductById(
        saved.data!.id,
      );
      expect(result.isSuccess, true);
      expect(result.data!.id, saved.data!.id);
    });

    test('getProductById retorna error si no existe', () async {
      final result = await productController.getProductById('INEXISTENTE');
      expect(result.isSuccess, false);
    });

    test('searchProducts filtra por nombre', () async {
      await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Lápiz Grafito',
        price: 10.0,
        stock: 100,
        category: 'Papelería',
        location: 'A1',
      );
      await productController.registerProduct(
        sku: 'SKU-002',
        name: 'Cuaderno',
        price: 25.0,
        stock: 50,
        category: 'Papelería',
        location: 'B1',
      );
      final result = await productController.searchProducts(query: 'Lápiz');
      expect(result.data, hasLength(1));
    });

    test('searchProducts retorna todos si no hay query', () async {
      await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Uno',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      final result = await productController.searchProducts();
      expect(result.data, hasLength(1));
    });

    test('updateProduct actualiza correctamente', () async {
      final saved = await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Original',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      final updated = saved.data!.copyWith(name: 'Actualizado');
      final result = await productController.updateProduct(
        product: updated,
      );
      expect(result.isSuccess, true);
      expect(result.data!.name, 'Actualizado');
    });

    test('updateProduct retorna error si no existe', () async {
      const nonExistent = Product(
        id: 'FAKE',
        sku: 'SKU-X',
        name: 'Fake',
        price: 10.0,
        stock: 5,
        category: 'Cat',
        location: 'A1',
      );
      final result = await productController.updateProduct(
        product: nonExistent,
      );
      expect(result.isSuccess, false);
    });

    test('deactivateProduct da de baja correctamente', () async {
      final saved = await productController.registerProduct(
        sku: 'SKU-001',
        name: 'Test',
        price: 10.0,
        stock: 5,
        category: 'Cat',
        location: 'A1',
      );
      final result = await productController.deactivateProduct(
        saved.data!.id,
      );
      expect(result.isSuccess, true);
      expect(result.data!.isActive, false);
    });

    test('deactivateProduct retorna error si no existe', () async {
      final result = await productController.deactivateProduct('INEXISTENTE');
      expect(result.isSuccess, false);
    });
  });
}
