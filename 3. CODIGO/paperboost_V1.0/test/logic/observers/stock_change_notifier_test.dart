import 'package:flutter_test/flutter_test.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/logic/observers/stock_change_notifier.dart';
import 'package:paperboost/logic/observers/stock_observer.dart';

class TestStockObserver implements StockObserver {
  final List<void Function()> stockChangedCalls = [];
  final List<void Function()> stockUnavailableCalls = [];
  Product? lastChangedProduct;
  int lastOldStock = 0;
  int lastNewStock = 0;
  Product? lastUnavailableProduct;

  @override
  void onStockChanged(Product product, int oldStock, int newStock) {
    lastChangedProduct = product;
    lastOldStock = oldStock;
    lastNewStock = newStock;
    stockChangedCalls.add(() {});
  }

  @override
  void onStockUnavailable(Product product) {
    lastUnavailableProduct = product;
    stockUnavailableCalls.add(() {});
  }
}

void main() {
  group('StockChangeNotifier', () {
    late StockChangeNotifier notifier;

    setUp(() {
      notifier = StockChangeNotifier.instance;
      notifier.clearObservers();
    });

    tearDown(() {
      notifier.clearObservers();
    });

    const product = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Test',
      price: 100.0,
      stock: 50,
      category: 'Test',
      location: 'A1',
    );

    test('observerCount es 0 al inicio', () {
      expect(notifier.observerCount, 0);
    });

    test('attach agrega observador', () {
      final observer = TestStockObserver();
      notifier.attach(observer);
      expect(notifier.observerCount, 1);
    });

    test('attach no duplica observadores', () {
      final observer = TestStockObserver();
      notifier.attach(observer);
      notifier.attach(observer);
      expect(notifier.observerCount, 1);
    });

    test('detach remueve observador', () {
      final observer = TestStockObserver();
      notifier.attach(observer);
      expect(notifier.observerCount, 1);
      notifier.detach(observer);
      expect(notifier.observerCount, 0);
    });

    test('notifyStockChanged notifica a observadores', () {
      final observer = TestStockObserver();
      notifier.attach(observer);

      notifier.notifyStockChanged(product, 50, 30);

      expect(observer.stockChangedCalls, hasLength(1));
      expect(observer.lastChangedProduct!.id, 'PROD-001');
      expect(observer.lastOldStock, 50);
      expect(observer.lastNewStock, 30);
    });

    test('notifyStockUnavailable notifica a observadores', () {
      final observer = TestStockObserver();
      notifier.attach(observer);

      notifier.notifyStockUnavailable(product);

      expect(observer.stockUnavailableCalls, hasLength(1));
      expect(observer.lastUnavailableProduct!.id, 'PROD-001');
    });

    test('notifica a múltiples observadores', () {
      final observer1 = TestStockObserver();
      final observer2 = TestStockObserver();
      notifier.attach(observer1);
      notifier.attach(observer2);

      notifier.notifyStockChanged(product, 10, 5);

      expect(observer1.stockChangedCalls, hasLength(1));
      expect(observer2.stockChangedCalls, hasLength(1));
    });

    test('clearObservers remueve todos los observadores', () {
      notifier.attach(TestStockObserver());
      notifier.attach(TestStockObserver());
      expect(notifier.observerCount, 2);

      notifier.clearObservers();
      expect(notifier.observerCount, 0);
    });

    test('no notifica a observadores removidos', () {
      final observer = TestStockObserver();
      notifier.attach(observer);
      notifier.detach(observer);

      notifier.notifyStockChanged(product, 10, 5);

      expect(observer.stockChangedCalls, isEmpty);
    });
  });

  group('StockChangeNotifier - Singleton', () {
    test('instance es singleton', () {
      final instance1 = StockChangeNotifier.instance;
      final instance2 = StockChangeNotifier.instance;
      expect(identical(instance1, instance2), true);
    });
  });
}
