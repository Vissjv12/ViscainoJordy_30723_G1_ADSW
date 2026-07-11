import '../../data/models/sale.dart';
import '../../data/models/sale_item.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';
import '../observers/stock_change_notifier.dart';
import '../results/operation_result.dart';
import '../validators/sale_validator.dart';

class SaleService {
  SaleService({
    required SaleRepository saleRepository,
    required ProductRepository productRepository,
    StockChangeNotifier? stockChangeNotifier,
  })  : _saleRepository = saleRepository,
        _productRepository = productRepository,
        _stockChangeNotifier =
            stockChangeNotifier ?? StockChangeNotifier.instance;

  static const double _taxRate = 0.15; // 15% IVA (ajustar según país)
  static int _saleIdCounter = 0;

  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;
  final StockChangeNotifier _stockChangeNotifier;

  Future<OperationResult<Sale>> createSale({
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
    String observations = '',
    String customerName = '',
    String customerEmail = '',
  }) async {
    // Validar items
    final itemErrors = SaleValidator.validateSaleItems(items);
    if (itemErrors.isNotEmpty) {
      return OperationResult<Sale>.failure(
        message: itemErrors.join('\n'),
      );
    }

    // Validar disponibilidad de stock
    final stockErrors = SaleValidator.validateStockForAllItems(items);
    if (stockErrors.isNotEmpty) {
      return OperationResult<Sale>.failure(
        message: stockErrors.join('\n'),
      );
    }

    // Validar información del cliente (opcional)
    final customerErrors = SaleValidator.validateCustomerInfo(
      customerName.isEmpty ? null : customerName,
      customerEmail.isEmpty ? null : customerEmail,
    );
    if (customerErrors.isNotEmpty) {
      return OperationResult<Sale>.failure(
        message: customerErrors.join('\n'),
      );
    }

    try {
      // Calcular totales
      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );

      final taxAmount = subtotal * _taxRate;
      final total = subtotal + taxAmount;

      // Generar número de venta
      final nextNumber = await _saleRepository.getNextSaleNumber();
      final saleNumber = _formatSaleNumber(nextNumber);

      // Crear venta
      final sale = Sale(
        id: _generateSaleId(),
        saleNumber: saleNumber,
        items: items,
        subtotal: subtotal,
        taxAmount: taxAmount,
        total: total,
        paymentMethod: paymentMethod,
        status: SaleStatus.completed,
        createdAt: DateTime.now(),
        observations: observations.trim(),
        customerName: customerName.trim(),
        customerEmail: customerEmail.trim(),
      );

      // Guardar venta
      await _saleRepository.save(sale);

      // Descontar stock y notificar
      await _decrementProductsStock(items);

      return OperationResult<Sale>.success(
        message: 'Nota de venta creada correctamente.',
        data: sale,
      );
    } catch (error) {
      return OperationResult<Sale>.failure(
        message: 'No se pudo crear la nota de venta: $error',
      );
    }
  }

  Future<OperationResult<Sale>> completeSale(String saleId) async {
    try {
      final sale = await _saleRepository.findById(saleId);

      if (sale == null) {
        return OperationResult<Sale>.failure(
          message: 'No se encontró la venta.',
        );
      }

      if (sale.isCompleted) {
        return OperationResult<Sale>.success(
          message: 'La venta ya estaba completada.',
          data: sale,
        );
      }

      if (!sale.isPending) {
        return OperationResult<Sale>.failure(
          message: 'Solo se pueden completar ventas pendientes.',
        );
      }

      final completedSale =
          sale.copyWith(status: SaleStatus.completed);

      await _saleRepository.update(completedSale);

      return OperationResult<Sale>.success(
        message: 'Venta completada correctamente.',
        data: completedSale,
      );
    } catch (error) {
      return OperationResult<Sale>.failure(
        message: 'No se pudo completar la venta: $error',
      );
    }
  }

  Future<OperationResult<void>> cancelSale(String saleId) async {
    try {
      final sale = await _saleRepository.findById(saleId);

      if (sale == null) {
        return OperationResult<void>.failure(
          message: 'No se encontró la venta.',
        );
      }

      if (sale.isCancelled) {
        return OperationResult<void>.failure(
          message: 'La venta ya está cancelada.',
        );
      }

      // Revertir stock
      await _restoreProductsStock(sale.items);

      // Cancelar venta
      await _saleRepository.cancel(saleId);

      return OperationResult<void>.success(
        message: 'Venta cancelada correctamente.',
      );
    } catch (error) {
      return OperationResult<void>.failure(
        message: 'No se pudo cancelar la venta: $error',
      );
    }
  }

  Future<OperationResult<List<Sale>>> getSales({
    bool includeCancelled = false,
  }) async {
    try {
      final sales = await _saleRepository.findAll(
        includeCompleted: true,
        includeCancelled: includeCancelled,
      );

      return OperationResult<List<Sale>>.success(
        message: sales.isEmpty
            ? 'No hay ventas registradas.'
            : 'Ventas consultadas correctamente.',
        data: sales,
      );
    } catch (error) {
      return OperationResult<List<Sale>>.failure(
        message: 'No se pudo consultar las ventas: $error',
      );
    }
  }

  Future<OperationResult<Sale>> getSaleById(String saleId) async {
    try {
      final sale = await _saleRepository.findById(saleId);

      if (sale == null) {
        return OperationResult<Sale>.failure(
          message: 'No se encontró la venta.',
        );
      }

      return OperationResult<Sale>.success(
        message: 'Venta consultada correctamente.',
        data: sale,
      );
    } catch (error) {
      return OperationResult<Sale>.failure(
        message: 'No se pudo consultar la venta: $error',
      );
    }
  }

  Future<OperationResult<List<Sale>>> searchSales({
    String query = '',
    SaleStatus? status,
  }) async {
    try {
      final sales = await _saleRepository.findAll(
        includeCompleted: true,
        includeCancelled: true,
      );

      final normalizedQuery = query.trim().toLowerCase();

      final filteredSales = sales.where((sale) {
        final matchesQuery = normalizedQuery.isEmpty ||
            sale.saleNumber.toLowerCase().contains(normalizedQuery) ||
            sale.customerName.toLowerCase().contains(normalizedQuery) ||
            sale.customerEmail.toLowerCase().contains(normalizedQuery);

        final matchesStatus = status == null || sale.status == status;

        return matchesQuery && matchesStatus;
      }).toList();

      return OperationResult<List<Sale>>.success(
        message: filteredSales.isEmpty
            ? 'No se encontraron ventas.'
            : 'Ventas consultadas correctamente.',
        data: filteredSales,
      );
    } catch (error) {
      return OperationResult<List<Sale>>.failure(
        message: 'No se pudo realizar la búsqueda: $error',
      );
    }
  }

  Future<void> _decrementProductsStock(List<SaleItem> items) async {
    for (final item in items) {
      final product = await _productRepository.findById(
        item.product.id,
      );

      if (product != null) {
        final oldStock = product.stock;
        final newStock = product.stock - item.quantity;
        final updatedProduct = product.copyWith(stock: newStock);

        await _productRepository.update(updatedProduct);

        // Notificar cambio de stock
        _stockChangeNotifier.notifyStockChanged(
          product,
          oldStock,
          newStock,
        );

        // Si el stock llega a 0, notificar que no hay disponibilidad
        if (newStock == 0) {
          _stockChangeNotifier.notifyStockUnavailable(updatedProduct);
        }
      }
    }
  }

  Future<void> _restoreProductsStock(List<SaleItem> items) async {
    for (final item in items) {
      final product = await _productRepository.findById(
        item.product.id,
      );

      if (product != null) {
        final oldStock = product.stock;
        final newStock = product.stock + item.quantity;
        final updatedProduct = product.copyWith(stock: newStock);

        await _productRepository.update(updatedProduct);

        _stockChangeNotifier.notifyStockChanged(
          product,
          oldStock,
          newStock,
        );
      }
    }
  }

  String _formatSaleNumber(int number) {
    return 'VTA-${number.toString().padLeft(6, '0')}';
  }

  String _generateSaleId() {
    _saleIdCounter++;
    return 'SALE-${_saleIdCounter.toString().padLeft(4, '0')}';
  }
}
