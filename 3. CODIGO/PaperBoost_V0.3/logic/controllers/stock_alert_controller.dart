import '../../data/models/stock_alert.dart';
import '../results/operation_result.dart';
import '../services/stock_alert_service.dart';

class StockAlertController {
  StockAlertController({
    required StockAlertService stockAlertService,
  }) : _stockAlertService = stockAlertService;

  final StockAlertService _stockAlertService;

  Future<OperationResult<StockAlert>> createAlert({
    required String productId,
    required int minimumQuantity,
  }) {
    return _stockAlertService.createAlert(
      productId: productId,
      minimumQuantity: minimumQuantity,
    );
  }

  Future<OperationResult<StockAlert>> updateAlert({
    required String id,
    required int minimumQuantity,
    required bool isActive,
  }) {
    return _stockAlertService.updateAlert(
      id: id,
      minimumQuantity: minimumQuantity,
      isActive: isActive,
    );
  }

  Future<OperationResult<StockAlert>> toggleAlertStatus(String id) {
    return _stockAlertService.toggleAlertStatus(id);
  }

  Future<OperationResult<List<StockAlert>>> getAlerts() {
    return _stockAlertService.getAlerts();
  }

  Future<OperationResult<StockAlert?>> getAlertByProductId(String productId) {
    return _stockAlertService.getAlertByProductId(productId);
  }

  Future<OperationResult<List<StockAlert>>> getTriggeredAlerts() {
    return _stockAlertService.getTriggeredAlerts();
  }
}
