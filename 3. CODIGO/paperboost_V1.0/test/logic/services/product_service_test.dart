import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/product_repository.dart';
import 'package:paperboost/logic/services/product_service.dart';

void main() {
  group('ProductService - RQF-003: Registrar Producto', () {
    late ProductService productService;
    late InMemoryProductRepository repository;

    setUp(() {
      repository = InMemoryProductRepository();
      productService = ProductService(
        productRepository: repository,
      );
    });

    test('registrar producto exitosamente', () async {
      final result = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Lápiz',
        price: 10.0,
        stock: 100,
        category: 'Papelería',
        location: 'A1',
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.sku, 'SKU-001');
      expect(result.message, contains('Producto registrado correctamente'));
    });

    test('rechazar producto con validación fallida', () async {
      final result = await productService.registerProduct(
        sku: '',
        name: '',
        price: 0,
        stock: -1,
        category: '',
        location: '',
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('El SKU es obligatorio'));
    });

    test('rechazar SKU duplicado', () async {
      await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Lápiz',
        price: 10.0,
        stock: 100,
        category: 'Papelería',
        location: 'A1',
      );

      final result = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Otro',
        price: 20.0,
        stock: 50,
        category: 'Papelería',
        location: 'A2',
      );

      expect(result.isSuccess, false);
      expect(result.message,
          contains('Ya existe un producto registrado con el SKU'));
    });

    test('normalizar SKU a mayúsculas', () async {
      final result = await productService.registerProduct(
        sku: '  sku-001  ',
        name: 'Producto',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );

      expect(result.isSuccess, true);
      expect(result.data!.sku, 'SKU-001');
    });
  });

  group('ProductService - RQF-011: Consultar Inventario', () {
    late ProductService productService;
    late InMemoryProductRepository repository;

    setUp(() async {
      repository = InMemoryProductRepository();
      productService = ProductService(
        productRepository: repository,
      );

      await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Lápiz',
        price: 10.0,
        stock: 100,
        category: 'Papelería',
        location: 'A1',
      );
      await productService.registerProduct(
        sku: 'SKU-002',
        name: 'Cuaderno',
        price: 25.0,
        stock: 50,
        category: 'Papelería',
        location: 'B1',
      );
    });

    test('getProducts retorna todos los productos activos', () async {
      final result = await productService.getProducts();
      expect(result.isSuccess, true);
      expect(result.data, hasLength(2));
    });

    test('getProducts retorna mensaje si no hay productos', () async {
      final emptyService = ProductService(
        productRepository: InMemoryProductRepository(),
      );
      final result = await emptyService.getProducts();
      expect(result.isSuccess, true);
      expect(result.message, contains('No existen productos registrados'));
    });

    test('getProducts incluye inactivos si se solicita', () async {
      final allProducts = await productService.getProducts();
      final productId = allProducts.data!.first.id;

      await productService.deactivateProduct(productId);

      final activeOnly = await productService.getProducts();
      expect(activeOnly.data, hasLength(1));

      final includeInactive = await productService.getProducts(
        includeInactive: true,
      );
      expect(includeInactive.data, hasLength(2));
    });

    test('getProductById encuentra producto', () async {
      final savedResult = await productService.registerProduct(
        sku: 'SKU-003',
        name: 'Producto',
        price: 30.0,
        stock: 20,
        category: 'Cat',
        location: 'C1',
      );
      final result = await productService.getProductById(
        savedResult.data!.id,
      );
      expect(result.isSuccess, true);
      expect(result.data!.sku, 'SKU-003');
    });

    test('getProductById rechaza ID vacío', () async {
      final result = await productService.getProductById('');
      expect(result.isSuccess, false);
      expect(result.message, contains('obligatorio'));
    });

    test('getProductById retorna failure para ID inexistente', () async {
      final result = await productService.getProductById('NO-EXISTE');
      expect(result.isSuccess, false);
      expect(result.message, contains('Producto no encontrado'));
    });
  });

  group('ProductService - RQF-012: Buscar Productos', () {
    late ProductService productService;

    setUp(() async {
      final repo = InMemoryProductRepository();
      productService = ProductService(productRepository: repo);

      await productService.registerProduct(
        sku: 'LAP-001',
        name: 'Lápiz Grafito',
        price: 10.0,
        stock: 100,
        category: 'Papelería',
        location: 'A1',
      );
      await productService.registerProduct(
        sku: 'CUA-001',
        name: 'Cuaderno Profesional',
        price: 35.0,
        stock: 50,
        category: 'Papelería',
        location: 'B1',
      );
      await productService.registerProduct(
        sku: 'RES-001',
        name: 'Resma Papel',
        price: 80.0,
        stock: 20,
        category: 'Papel',
        location: 'C1',
      );
    });

    test('buscar por nombre', () async {
      final result = await productService.searchProducts(query: 'Lápiz');
      expect(result.isSuccess, true);
      expect(result.data, hasLength(1));
      expect(result.data!.first.name, 'Lápiz Grafito');
    });

    test('buscar por SKU', () async {
      final result = await productService.searchProducts(query: 'CUA');
      expect(result.isSuccess, true);
      expect(result.data, hasLength(1));
    });

    test('buscar sin query retorna todos', () async {
      final result = await productService.searchProducts();
      expect(result.data, hasLength(3));
    });

    test('buscar sin coincidencias', () async {
      final result = await productService.searchProducts(query: 'zzzzz');
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
      expect(result.message, contains('No se encontraron productos'));
    });

    test('filtrar por categoría', () async {
      final result = await productService.searchProducts(category: 'Papel');
      expect(result.data, hasLength(1));
    });

    test('ordenar por precio ascendente', () async {
      final result = await productService.searchProducts(
        sortOption: ProductSortOption.price,
        ascending: true,
      );
      expect(result.data![0].price, 10.0);
      expect(result.data![2].price, 80.0);
    });

    test('ordenar por stock descendente', () async {
      final result = await productService.searchProducts(
        sortOption: ProductSortOption.stock,
        ascending: false,
      );
      expect(result.data![0].stock, 100);
    });

    test('filtrar por estado activo', () async {
      final result = await productService.searchProducts(
        status: ProductStatus.active,
      );
      expect(result.isSuccess, true);
      expect(result.data, hasLength(3));
    });
  });

  group('ProductService - RQF-013: Editar Producto', () {
    late ProductService productService;

    setUp(() async {
      final repo = InMemoryProductRepository();
      productService = ProductService(productRepository: repo);
    });

    test('actualizar producto exitosamente', () async {
      final saved = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Original',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );

      final updatedProduct = saved.data!.copyWith(
        name: 'Actualizado',
        price: 20.0,
      );

      final result = await productService.updateProduct(
        product: updatedProduct,
      );
      expect(result.isSuccess, true);
      expect(result.data!.name, 'Actualizado');
    });

    test('rechazar actualización de producto inexistente', () async {
      const nonExistent = Product(
        id: 'NO-EXISTE',
        sku: 'SKU-X',
        name: 'No existe',
        price: 10.0,
        stock: 5,
        category: 'Cat',
        location: 'A1',
      );

      final result = await productService.updateProduct(
        product: nonExistent,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('no existe'));
    });

    test('rechazar actualización con datos inválidos', () async {
      final saved = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Original',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );

      final invalidProduct = saved.data!.copyWith(
        price: 0,
        name: '',
      );

      final result = await productService.updateProduct(
        product: invalidProduct,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('obligatorio'));
    });

    test('rechazar SKU duplicado en actualización', () async {
      await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Producto 1',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      final saved2 = await productService.registerProduct(
        sku: 'SKU-002',
        name: 'Producto 2',
        price: 20.0,
        stock: 20,
        category: 'Cat',
        location: 'A2',
      );

      final withDuplicatedSku = saved2.data!.copyWith(sku: 'SKU-001');
      final result = await productService.updateProduct(
        product: withDuplicatedSku,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('Ya existe otro producto con el SKU'));
    });
  });

  group('ProductService - RQF-023: Dar de Baja Producto', () {
    late ProductService productService;

    setUp(() async {
      final repo = InMemoryProductRepository();
      productService = ProductService(productRepository: repo);
    });

    test('dar de baja producto activo', () async {
      final saved = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Producto',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );

      final result = await productService.deactivateProduct(
        saved.data!.id,
      );
      expect(result.isSuccess, true);
      expect(result.data!.status, ProductStatus.inactive);
      expect(result.data!.isActive, false);
    });

    test('rechazar baja de producto inexistente', () async {
      final result = await productService.deactivateProduct('NO-EXISTE');
      expect(result.isSuccess, false);
      expect(result.message, contains('no existe'));
    });

    test('rechazar baja de producto ya inactivo', () async {
      final saved = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Producto',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );

      await productService.deactivateProduct(saved.data!.id);
      final result = await productService.deactivateProduct(
        saved.data!.id,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('ya se encuentra dado de baja'));
    });
  });

  group('ProductService - Catch blocks', () {
    late ProductService productService;

    test('registerProduct maneja error del repositorio', () async {
      final throwingRepo = _ThrowingProductRepository();
      productService = ProductService(productRepository: throwingRepo);

      final result = await productService.registerProduct(
        sku: 'SKU-001',
        name: 'Producto',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo registrar el producto'));
    });

    test('getProducts maneja error del repositorio', () async {
      final throwingRepo = _ThrowingProductRepository();
      productService = ProductService(productRepository: throwingRepo);
      final result = await productService.getProducts();
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo consultar el inventario'));
    });

    test('searchProducts maneja error del repositorio', () async {
      final throwingRepo = _ThrowingProductRepository();
      productService = ProductService(productRepository: throwingRepo);
      final result = await productService.searchProducts(query: 'test');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo realizar la búsqueda'));
    });

    test('updateProduct maneja error del repositorio', () async {
      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Producto',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      final throwingRepo = _ThrowingProductRepository(productToFind: product);
      productService = ProductService(productRepository: throwingRepo);

      final result = await productService.updateProduct(product: product);
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo actualizar el producto'));
    });

    test('deactivateProduct maneja error del repositorio', () async {
      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Producto',
        price: 10.0,
        stock: 10,
        category: 'Cat',
        location: 'A1',
      );
      final throwingRepo = _ThrowingProductRepository(productToFind: product);
      productService = ProductService(productRepository: throwingRepo);

      final result = await productService.deactivateProduct('PROD-001');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo dar de baja el producto'));
    });
  });
}

class _ThrowingProductRepository implements ProductRepository {
  final Product? productToFind;

  _ThrowingProductRepository({this.productToFind});

  @override
  Future<List<Product>> findAll({bool includeInactive = false}) async {
    throw Exception('Simulated error');
  }

  @override
  Future<Product?> findById(String id) async => productToFind;

  @override
  Future<Product?> findBySku(String sku) async => null;

  @override
  Future<bool> existsBySku(String sku, {String? excludingProductId}) async =>
      false;

  @override
  Future<void> save(Product product) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> update(Product product) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> deactivate(String id) async {
    throw Exception('Simulated error');
  }
}
