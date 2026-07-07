import '../models/stock_alert.dart';
import 'stock_alert_repository.dart';

class InMemoryStockAlertRepository implements StockAlertRepository {
  final List<StockAlert> _alerts = [];

  @override
  Future<List<StockAlert>> findAll() async {
    return List<StockAlert>.unmodifiable(_alerts);
  }

  @override
  Future<StockAlert?> findById(String id) async {
    for (final alert in _alerts) {
      if (alert.id == id) {
        return alert;
      }
    }
    return null;
  }

  @override
  Future<StockAlert?> findByProductId(String productId) async {
    for (final alert in _alerts) {
      if (alert.productId == productId) {
        return alert;
      }
    }
    return null;
  }

  @override
  Future<void> save(StockAlert alert) async {
    final duplicatedId = _alerts.any(
      (currentAlert) => currentAlert.id == alert.id,
    );

    if (duplicatedId) {
      throw StateError(
        'Ya existe una alerta con el identificador ${alert.id}.',
      );
    }

    final duplicatedProduct = _alerts.any(
      (currentAlert) => currentAlert.productId == alert.productId,
    );

    if (duplicatedProduct) {
      throw StateError(
        'Ya existe una alerta configurada para el producto ${alert.productId}.',
      );
    }

    _alerts.add(alert);
  }

  @override
  Future<void> update(StockAlert alert) async {
    final index = _alerts.indexWhere(
      (currentAlert) => currentAlert.id == alert.id,
    );

    if (index == -1) {
      throw StateError(
        'No se encontró la alerta que se desea actualizar.',
      );
    }

    _alerts[index] = alert;
  }

  @override
  Future<void> delete(String id) async {
    _alerts.removeWhere((alert) => alert.id == id);
  }
}
