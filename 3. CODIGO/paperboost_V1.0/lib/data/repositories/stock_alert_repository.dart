import '../models/stock_alert.dart';

abstract class StockAlertRepository {
  Future<List<StockAlert>> findAll();

  Future<StockAlert?> findById(String id);

  Future<StockAlert?> findByProductId(String productId);

  Future<void> save(StockAlert alert);

  Future<void> update(StockAlert alert);

  Future<void> delete(String id);
}
