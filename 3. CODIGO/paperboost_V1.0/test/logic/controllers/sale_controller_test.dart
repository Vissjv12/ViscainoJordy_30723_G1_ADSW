import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale.dart';
import 'package:paperboost/data/models/sale_item.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_sale_repository.dart';
import 'package:paperboost/logic/controllers/sale_controller.dart';
import 'package:paperboost/logic/services/sale_service.dart';

void main() {
  group('SaleController - Crear Venta', () {
    late SaleController saleController;
    late Product testProduct;

    setUp(() async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      testProduct = const Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(testProduct);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      saleController = SaleController(saleService: saleService);
    });

    test('Delegar creación de venta al servicio', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 5,
        unitPrice: 100.0,
      );

      final result = await saleController.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isSuccess, true);
      expect(result.data!.saleNumber, startsWith('VTA-'));
    });

    test('Retornar error si falla la creación', () async {
      final result = await saleController.createSale(
        items: [],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isSuccess, false);
    });
  });

  group('SaleController - Obtener Ventas', () {
    late SaleController saleController;

    setUp(() async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      saleController = SaleController(saleService: saleService);
    });

    test('Obtener lista de ventas', () async {
      final result = await saleController.getSales();

      expect(result.isSuccess, true);
      expect(result.data, isA<List<Sale>>());
    });
  });

  group('SaleController - Completar Venta', () {
    late SaleController saleController;
    late String saleId;

    setUp(() async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      saleController = SaleController(saleService: saleService);

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleController.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      saleId = createResult.data!.id;
    });

    test('Completar venta correctamente', () async {
      final result = await saleController.completeSale(saleId);

      expect(result.isSuccess, true);
    });
  });

  group('SaleController - Cancelar Venta', () {
    late SaleController saleController;
    late String saleId;

    setUp(() async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      saleController = SaleController(saleService: saleService);

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleController.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      saleId = createResult.data!.id;
    });

    test('Cancelar venta correctamente', () async {
      final result = await saleController.cancelSale(saleId);

      expect(result.isSuccess, true);
    });

    test('Cancelar venta inexistente retorna error', () async {
      final result = await saleController.cancelSale('ID_INEXISTENTE');

      expect(result.isSuccess, false);
    });
  });

  group('SaleController - Completar Venta Error', () {
    test('Completar venta inexistente retorna error', () async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();
      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
      final controller = SaleController(saleService: saleService);

      final result = await controller.completeSale('ID_INEXISTENTE');

      expect(result.isSuccess, false);
    });
  });

  group('SaleController - Obtener Venta por ID', () {
    late SaleController saleController;
    late String saleId;

    setUp(() async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      saleController = SaleController(saleService: saleService);

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleController.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      saleId = createResult.data!.id;
    });

    test('Obtener venta existente por ID', () async {
      final result = await saleController.getSaleById(saleId);

      expect(result.isSuccess, true);
      expect(result.data!.id, saleId);
    });

    test('Obtener venta inexistente por ID retorna error', () async {
      final result = await saleController.getSaleById('ID_INEXISTENTE');

      expect(result.isSuccess, false);
    });
  });

  group('SaleController - Buscar Ventas', () {
    test('Buscar ventas sin query retorna todas', () async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      final controller = SaleController(saleService: saleService);

      final result = await controller.searchSales();

      expect(result.isSuccess, true);
      expect(result.data, isA<List<Sale>>());
    });

    test('Buscar ventas con query existente', () async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );

      final controller = SaleController(saleService: saleService);

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      await controller.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      final result = await controller.searchSales(query: 'VTA-');

      expect(result.isSuccess, true);
      expect(result.data!.isNotEmpty, true);
    });
  });
}
