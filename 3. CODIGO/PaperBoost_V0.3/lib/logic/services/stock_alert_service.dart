import '../../data/models/stock_alert.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/stock_alert_repository.dart';
import '../results/operation_result.dart';
import '../validators/stock_alert_validator.dart';

class StockAlertService {
  StockAlertService({
    required StockAlertRepository stockAlertRepository,
    required ProductRepository productRepository,
  })  : _stockAlertRepository = stockAlertRepository,
        _productRepository = productRepository;

  final StockAlertRepository _stockAlertRepository;
  final ProductRepository _productRepository;

  Future<OperationResult<StockAlert>> createAlert({
    required String productId,
    required int minimumQuantity,
  }) async {
    final product = await _productRepository.findById(productId);
    if (product == null) {
      return OperationResult<StockAlert>.failure(
        message: 'El producto especificado no existe.',
      );
    }

    final existingAlert = await _stockAlertRepository.findByProductId(productId);
    if (existingAlert != null) {
      return OperationResult<StockAlert>.failure(
        message: 'Ya existe una alerta configurada para este producto.',
      );
    }

    final alert = StockAlert(
      id: 'ALERT-${DateTime.now().microsecondsSinceEpoch}',
      productId: productId,
      minimumQuantity: minimumQuantity,
      isActive: true,
    );

    final validationErrors = StockAlertValidator.validate(alert);
    if (validationErrors.isNotEmpty) {
      return OperationResult<StockAlert>.failure(
        message: validationErrors.join('\n'),
      );
    }

    try {
      await _stockAlertRepository.save(alert);
      return OperationResult<StockAlert>.success(
        message: 'Alerta de stock creada correctamente.',
        data: alert,
      );
    } catch (error) {
      return OperationResult<StockAlert>.failure(
        message: 'Error al registrar la alerta: $error',
      );
    }
  }

  Future<OperationResult<StockAlert>> updateAlert({
    required String id,
    required int minimumQuantity,
    required bool isActive,
  }) async {
    final alert = await _stockAlertRepository.findById(id);
    if (alert == null) {
      return OperationResult<StockAlert>.failure(
        message: 'La alerta especificada no existe.',
      );
    }

    final updatedAlert = alert.copyWith(
      minimumQuantity: minimumQuantity,
      isActive: isActive,
    );

    final validationErrors = StockAlertValidator.validate(updatedAlert);
    if (validationErrors.isNotEmpty) {
      return OperationResult<StockAlert>.failure(
        message: validationErrors.join('\n'),
      );
    }

    try {
      await _stockAlertRepository.update(updatedAlert);
      return OperationResult<StockAlert>.success(
        message: 'Alerta de stock actualizada correctamente.',
        data: updatedAlert,
      );
    } catch (error) {
      return OperationResult<StockAlert>.failure(
        message: 'Error al actualizar la alerta: $error',
      );
    }
  }

  Future<OperationResult<StockAlert>> toggleAlertStatus(String id) async {
    final alert = await _stockAlertRepository.findById(id);
    if (alert == null) {
      return OperationResult<StockAlert>.failure(
        message: 'La alerta especificada no existe.',
      );
    }

    final updatedAlert = alert.copyWith(isActive: !alert.isActive);

    try {
      await _stockAlertRepository.update(updatedAlert);
      final msg = updatedAlert.isActive
          ? 'Alerta activada correctamente.'
          : 'Alerta desactivada correctamente.';
      return OperationResult<StockAlert>.success(
        message: msg,
        data: updatedAlert,
      );
    } catch (error) {
      return OperationResult<StockAlert>.failure(
        message: 'Error al cambiar estado de la alerta: $error',
      );
    }
  }

  Future<OperationResult<List<StockAlert>>> getAlerts() async {
    try {
      final alerts = await _stockAlertRepository.findAll();
      return OperationResult<List<StockAlert>>.success(
        message: 'Alertas consultadas correctamente.',
        data: alerts,
      );
    } catch (error) {
      return OperationResult<List<StockAlert>>.failure(
        message: 'Error al consultar alertas: $error',
      );
    }
  }

  Future<OperationResult<StockAlert?>> getAlertByProductId(String productId) async {
    try {
      final alert = await _stockAlertRepository.findByProductId(productId);
      return OperationResult<StockAlert?>.success(
        message: 'Alerta consultada correctamente.',
        data: alert,
      );
    } catch (error) {
      return OperationResult<StockAlert?>.failure(
        message: 'Error al consultar la alerta del producto: $error',
      );
    }
  }

  Future<OperationResult<List<StockAlert>>> getTriggeredAlerts() async {
    try {
      final alerts = await _stockAlertRepository.findAll();
      final triggered = <StockAlert>[];

      for (final alert in alerts) {
        if (alert.isActive) {
          final product = await _productRepository.findById(alert.productId);
          if (product != null && product.stock <= alert.minimumQuantity) {
            triggered.add(alert);
          }
        }
      }

      return OperationResult<List<StockAlert>>.success(
        message: 'Alertas activadas consultadas correctamente.',
        data: triggered,
      );
    } catch (error) {
      return OperationResult<List<StockAlert>>.failure(
        message: 'Error al consultar alertas activadas: $error',
      );
    }
  }
}
