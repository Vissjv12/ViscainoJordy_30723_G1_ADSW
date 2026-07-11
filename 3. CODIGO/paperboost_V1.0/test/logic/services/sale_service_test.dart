import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale.dart';
import 'package:paperboost/data/models/sale_item.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_sale_repository.dart';
import 'package:paperboost/data/repositories/sale_repository.dart';
import 'package:paperboost/logic/observers/stock_change_notifier.dart';
import 'package:paperboost/logic/observers/stock_observer.dart';
import 'package:paperboost/logic/services/sale_service.dart';

void main() {
  group('SaleService - Crear Venta', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;
    late Product testProduct;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

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

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('Crear venta con items válidos', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 5,
        unitPrice: 100.0,
      );

      final result = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.total, 575.0); // 500 + 75 IVA
    });

    test('Fallar al crear venta sin items', () async {
      final result = await saleService.createSale(
        items: [],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('al menos un producto'));
    });

    test('Fallar al crear venta con stock insuficiente', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 100, // Mayor que stock disponible (50)
        unitPrice: 100.0,
      );

      final result = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Stock insuficiente'));
    });

    test('Descontar stock automáticamente después de crear venta', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 10,
        unitPrice: 100.0,
      );

      await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      final updatedProduct = await productRepository.findById('PROD-001');

      expect(updatedProduct!.stock, 40); // 50 - 10
    });

    test('Generar número de venta único', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 1,
        unitPrice: 100.0,
      );

      final result1 = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      final result2 = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result1.data!.saleNumber, isNot(result2.data!.saleNumber));
    });

    test('Calcular IVA correctamente (15%)', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 1,
        unitPrice: 100.0,
      );

      final result = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(result.data!.subtotal, 100.0);
      expect(result.data!.taxAmount, 15.0);
      expect(result.data!.total, 115.0);
    });
  });

  group('SaleService - Completar Venta', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('Completar venta pendiente', () async {
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

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      final completeResult =
          await saleService.completeSale(createResult.data!.id);

      expect(completeResult.isSuccess, true);
      expect(completeResult.data!.status, SaleStatus.completed);
    });
  });

  group('SaleService - Cancelar Venta', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('Cancelar venta y restaurar stock', () async {
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

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 10,
        unitPrice: 100.0,
      );

      final createResult = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      // Stock debe ser 40 después de crear venta
      var currentProduct = await productRepository.findById('PROD-001');
      expect(currentProduct!.stock, 40);

      // Cancelar venta
      await saleService.cancelSale(createResult.data!.id);

      // Stock debe volver a 50
      currentProduct = await productRepository.findById('PROD-001');
      expect(currentProduct!.stock, 50);
    });
  });

  group('SaleService - Observer Pattern', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;
    late StockChangeNotifier notifier;

    setUp(() {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();
      notifier = StockChangeNotifier.instance;
      notifier.clearObservers();

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
        stockChangeNotifier: notifier,
      );
    });

    test('Observer recibe notificación de cambio de stock', () async {
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

      var stockChangeNotified = false;

      notifier.attach(
        _MockStockObserver(
          onStockChanged: (p, old, n) {
            stockChangeNotified = true;
          },
        ),
      );

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 10,
        unitPrice: 100.0,
      );

      await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(stockChangeNotified, true);
    });
  });

  group('SaleService - Validación de Cliente', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;
    late Product testProduct;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

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

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('Fallar al crear venta con nombre de cliente muy corto', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 1,
        unitPrice: 100.0,
      );

      final result = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
        customerName: 'AB',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('nombre del cliente'));
    });

    test('Fallar al crear venta con correo de cliente inválido', () async {
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 1,
        unitPrice: 100.0,
      );

      final result = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
        customerEmail: 'correo-invalido',
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('correo electrónico válido'));
    });
  });

  group('SaleService - Completar Venta (Casos borde)', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('Fallar al completar venta inexistente', () async {
      final result = await saleService.completeSale('NO-EXISTE');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se encontró la venta'));
    });

    test('Completar venta pendiente guardada manualmente', () async {
      final pendingSale = Sale(
        id: 'SALE-PENDING-001',
        saleNumber: 'VTA-000001',
        items: [],
        subtotal: 0,
        taxAmount: 0,
        total: 0,
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.pending,
        createdAt: DateTime.now(),
      );

      await saleRepository.save(pendingSale);

      final result = await saleService.completeSale('SALE-PENDING-001');

      expect(result.isSuccess, true);
      expect(result.data!.status, SaleStatus.completed);
      expect(result.message, 'Venta completada correctamente.');
    });

    test('Fallar al completar venta cancelada', () async {
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

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      await saleService.cancelSale(createResult.data!.id);

      final result = await saleService.completeSale(createResult.data!.id);
      expect(result.isSuccess, false);
      expect(result.message, contains('pendientes'));
    });
  });

  group('SaleService - Cancelar Venta (Casos borde)', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('Fallar al cancelar venta inexistente', () async {
      final result = await saleService.cancelSale('NO-EXISTE');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se encontró la venta'));
    });

    test('Fallar al cancelar venta ya cancelada', () async {
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

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      await saleService.cancelSale(createResult.data!.id);

      final result = await saleService.cancelSale(createResult.data!.id);
      expect(result.isSuccess, false);
      expect(result.message, contains('ya está cancelada'));
    });
  });

  group('SaleService - Consultar Ventas', () {
    late SaleService saleService;
    late InMemorySaleRepository saleRepository;
    late InMemoryProductRepository productRepository;

    setUp(() async {
      saleRepository = InMemorySaleRepository();
      productRepository = InMemoryProductRepository();

      saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
      );
    });

    test('getSaleById retorna failure para venta inexistente', () async {
      final result = await saleService.getSaleById('NO-EXISTE');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se encontró la venta'));
    });

    test('getSaleById retorna venta exitosamente', () async {
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

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final createResult = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      final result = await saleService.getSaleById(createResult.data!.id);
      expect(result.isSuccess, true);
      expect(result.data!.id, createResult.data!.id);
    });

    test('getSales retorna mensaje si no hay ventas', () async {
      final result = await saleService.getSales();
      expect(result.isSuccess, true);
      expect(result.message, contains('No hay ventas registradas'));
    });
  });

  group('SaleService - Stock Cero', () {
    test('Observer recibe notificación de stock agotado', () async {
      final saleRepository = InMemorySaleRepository();
      final productRepository = InMemoryProductRepository();
      final notifier = StockChangeNotifier.instance;
      notifier.clearObservers();

      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Product Test',
        price: 100.0,
        stock: 1,
        category: 'Test',
        location: 'A1',
      );

      await productRepository.save(product);

      final saleService = SaleService(
        saleRepository: saleRepository,
        productRepository: productRepository,
        stockChangeNotifier: notifier,
      );

      var stockUnavailableNotified = false;

      notifier.attach(
        _MockStockObserver(
          onStockUnavailable: (p) {
            stockUnavailableNotified = true;
          },
        ),
      );

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );

      expect(stockUnavailableNotified, true);
    });
  });

  group('SaleService - Catch blocks', () {
    test('createSale maneja error del repositorio', () async {
      final productRepository = InMemoryProductRepository();
      final throwingRepo = _ThrowingSaleRepository();

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
        saleRepository: throwingRepo,
        productRepository: productRepository,
      );

      final item = SaleItem(
        id: 'ITEM-001',
        product: product,
        quantity: 1,
        unitPrice: 100.0,
      );

      final result = await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
      );
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo crear la nota de venta'));
    });

    test('completeSale maneja error del repositorio', () async {
      final throwingRepo = _ThrowingSaleRepository();
      final productRepository = InMemoryProductRepository();

      final saleService = SaleService(
        saleRepository: throwingRepo,
        productRepository: productRepository,
      );

      final result = await saleService.completeSale('SALE-001');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo completar la venta'));
    });

    test('cancelSale maneja error del repositorio', () async {
      final throwingRepo = _ThrowingSaleRepository();
      final productRepository = InMemoryProductRepository();

      final saleService = SaleService(
        saleRepository: throwingRepo,
        productRepository: productRepository,
      );

      final result = await saleService.cancelSale('SALE-001');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo cancelar la venta'));
    });

    test('getSales maneja error del repositorio', () async {
      final throwingRepo = _ThrowingSaleRepository();
      final productRepository = InMemoryProductRepository();

      final saleService = SaleService(
        saleRepository: throwingRepo,
        productRepository: productRepository,
      );

      final result = await saleService.getSales();
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo consultar las ventas'));
    });

    test('getSaleById maneja error del repositorio', () async {
      final throwingRepo = _ThrowingSaleRepository();
      final productRepository = InMemoryProductRepository();

      final saleService = SaleService(
        saleRepository: throwingRepo,
        productRepository: productRepository,
      );

      final result = await saleService.getSaleById('SALE-001');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo consultar la venta'));
    });

    test('searchSales maneja error del repositorio', () async {
      final throwingRepo = _ThrowingSaleRepository();
      final productRepository = InMemoryProductRepository();

      final saleService = SaleService(
        saleRepository: throwingRepo,
        productRepository: productRepository,
      );

      final result = await saleService.searchSales(query: 'test');
      expect(result.isSuccess, false);
      expect(result.message, contains('No se pudo realizar la búsqueda'));
    });
  });
}

class _ThrowingSaleRepository implements SaleRepository {
  @override
  Future<List<Sale>> findAll({
    bool includeCompleted = false,
    bool includeCancelled = false,
  }) async {
    throw Exception('Simulated error');
  }

  @override
  Future<Sale?> findById(String id) async {
    throw Exception('Simulated error');
  }

  @override
  Future<Sale?> findBySaleNumber(String saleNumber) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> save(Sale sale) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> update(Sale sale) async {
    throw Exception('Simulated error');
  }

  @override
  Future<void> cancel(String id) async {
    throw Exception('Simulated error');
  }

  @override
  Future<int> getNextSaleNumber() async {
    throw Exception('Simulated error');
  }
}

class _MockStockObserver implements StockObserver {
  _MockStockObserver({
    void Function(Product, int, int)? onStockChanged,
    void Function(Product)? onStockUnavailable,
  })  : _onStockChanged = onStockChanged,
        _onStockUnavailable = onStockUnavailable;

  final void Function(Product, int, int)? _onStockChanged;
  final void Function(Product)? _onStockUnavailable;

  @override
  void onStockChanged(Product product, int oldStock, int newStock) {
    _onStockChanged?.call(product, oldStock, newStock);
  }

  @override
  void onStockUnavailable(Product product) {
    _onStockUnavailable?.call(product);
  }
}
