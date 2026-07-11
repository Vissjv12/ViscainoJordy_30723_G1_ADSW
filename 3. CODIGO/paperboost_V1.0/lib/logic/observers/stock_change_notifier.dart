import '../../data/models/product.dart';
import 'stock_observer.dart';

/// Implementa el patrón Observer para notificaciones de cambios de stock.
/// 
/// Este notificador es un Singleton que gestiona observadores interesados
/// en cambios de inventario. Cuando el stock de un producto cambia,
/// notifica automáticamente a todos los observadores registrados.
class StockChangeNotifier {
  StockChangeNotifier._internal();

  static final StockChangeNotifier _instance =
      StockChangeNotifier._internal();

  static StockChangeNotifier get instance => _instance;

  final List<StockObserver> _observers = [];

  void attach(StockObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  void detach(StockObserver observer) {
    _observers.remove(observer);
  }

  void notifyStockChanged(
    Product product,
    int oldStock,
    int newStock,
  ) {
    for (final observer in _observers) {
      observer.onStockChanged(product, oldStock, newStock);
    }
  }

  void notifyStockUnavailable(Product product) {
    for (final observer in _observers) {
      observer.onStockUnavailable(product);
    }
  }

  void clearObservers() {
    _observers.clear();
  }

  int get observerCount => _observers.length;
}
