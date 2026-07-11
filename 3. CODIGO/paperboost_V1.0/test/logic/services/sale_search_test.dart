import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/sale_item.dart';
import 'package:paperboost/data/models/sale.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_sale_repository.dart';
import 'package:paperboost/logic/services/sale_service.dart';

void main() {
  group('SaleService - Búsqueda de Ventas', () {
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

      // Crear algunas ventas
      final item = SaleItem(
        id: 'ITEM-001',
        product: testProduct,
        quantity: 1,
        unitPrice: 100.0,
      );

      await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Juan Perez',
        customerEmail: 'juan@example.com',
        observations: 'First sale',
      );

      await saleService.createSale(
        items: [item],
        paymentMethod: PaymentMethod.card,
        customerName: 'Maria Gomez',
        customerEmail: 'maria@example.com',
        observations: 'Second sale',
      );
    });

    test('Buscar venta por número de nota exacto/parcial', () async {
      // Debería encontrar VTA-000001
      final result = await saleService.searchSales(query: 'VTA-000001');

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data!.first.customerName, 'Juan Perez');
    });

    test('Buscar venta por nombre de cliente', () async {
      final result = await saleService.searchSales(query: 'maria');

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data!.first.customerName, 'Maria Gomez');
    });

    test('Buscar venta por email de cliente', () async {
      final result = await saleService.searchSales(query: 'juan@example.com');

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data!.first.customerName, 'Juan Perez');
    });

    test('Buscar venta con consulta vacía retorna todas', () async {
      final result = await saleService.searchSales(query: '');

      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
    });

    test('Filtrar por estado de venta', () async {
      final allSalesResult = await saleService.getSales(includeCancelled: true);
      final saleId = allSalesResult.data!.first.id;

      // Cancelamos una venta
      await saleService.cancelSale(saleId);

      final completedSearch = await saleService.searchSales(
        status: SaleStatus.completed,
      );
      final cancelledSearch = await saleService.searchSales(
        status: SaleStatus.cancelled,
      );

      expect(completedSearch.data!.length, 1);
      expect(cancelledSearch.data!.length, 1);
    });
  });
}
