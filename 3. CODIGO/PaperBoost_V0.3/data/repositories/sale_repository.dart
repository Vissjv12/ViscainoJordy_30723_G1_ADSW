import '../models/sale.dart';

abstract class SaleRepository {
  Future<List<Sale>> findAll({
    bool includeCompleted = false,
    bool includeCancelled = false,
  });

  Future<Sale?> findById(String id);

  Future<Sale?> findBySaleNumber(String saleNumber);

  Future<void> save(Sale sale);

  Future<void> update(Sale sale);

  Future<void> cancel(String id);

  Future<int> getNextSaleNumber();
}
