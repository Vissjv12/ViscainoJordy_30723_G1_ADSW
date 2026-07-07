import '../../data/models/product.dart';

abstract class StockObserver {
  void onStockChanged(Product product, int oldStock, int newStock);

  void onStockUnavailable(Product product);
}
