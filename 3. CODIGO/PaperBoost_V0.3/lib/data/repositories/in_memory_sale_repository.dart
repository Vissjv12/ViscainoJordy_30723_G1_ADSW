import '../models/sale.dart';
import 'sale_repository.dart';

class InMemorySaleRepository implements SaleRepository {
  final List<Sale> _sales = [];
  int _saleCounter = 0;

  @override
  Future<List<Sale>> findAll({
    bool includeCompleted = false,
    bool includeCancelled = false,
  }) async {
    var sales = List<Sale>.from(_sales);

    if (!includeCompleted) {
      sales =
          sales.where((sale) => sale.status != SaleStatus.completed).toList();
    }

    if (!includeCancelled) {
      sales =
          sales.where((sale) => sale.status != SaleStatus.cancelled).toList();
    }

    sales.sort((first, second) =>
        second.createdAt.compareTo(first.createdAt));

    return List<Sale>.unmodifiable(sales);
  }

  @override
  Future<Sale?> findById(String id) async {
    for (final sale in _sales) {
      if (sale.id == id) {
        return sale;
      }
    }

    return null;
  }

  @override
  Future<Sale?> findBySaleNumber(String saleNumber) async {
    final normalizedNumber = saleNumber.trim().toUpperCase();

    for (final sale in _sales) {
      if (sale.saleNumber == normalizedNumber) {
        return sale;
      }
    }

    return null;
  }

  @override
  Future<void> save(Sale sale) async {
    final duplicatedId = _sales.any(
      (currentSale) => currentSale.id == sale.id,
    );

    if (duplicatedId) {
      throw StateError(
        'Ya existe una venta con el identificador ${sale.id}.',
      );
    }

    _sales.add(sale);
  }

  @override
  Future<void> update(Sale sale) async {
    final index = _sales.indexWhere(
      (currentSale) => currentSale.id == sale.id,
    );

    if (index == -1) {
      throw StateError(
        'No se encontró la venta que se desea actualizar.',
      );
    }

    _sales[index] = sale;
  }

  @override
  Future<void> cancel(String id) async {
    final index = _sales.indexWhere((sale) => sale.id == id);

    if (index == -1) {
      throw StateError(
        'No se encontró la venta que se desea cancelar.',
      );
    }

    final sale = _sales[index];

    _sales[index] = sale.copyWith(status: SaleStatus.cancelled);
  }

  @override
  Future<int> getNextSaleNumber() async {
    _saleCounter++;

    return _saleCounter;
  }
}
