import '../../data/models/sale.dart';
import '../../data/models/sale_item.dart';
import '../results/operation_result.dart';
import '../services/sale_service.dart';

class SaleController {
  SaleController({
    required SaleService saleService,
  }) : _saleService = saleService;

  final SaleService _saleService;

  Future<OperationResult<Sale>> createSale({
    required List<SaleItem> items,
    required PaymentMethod paymentMethod,
    String observations = '',
    String customerName = '',
    String customerEmail = '',
  }) {
    return _saleService.createSale(
      items: items,
      paymentMethod: paymentMethod,
      observations: observations,
      customerName: customerName,
      customerEmail: customerEmail,
    );
  }

  Future<OperationResult<Sale>> completeSale(String saleId) {
    return _saleService.completeSale(saleId);
  }

  Future<OperationResult<void>> cancelSale(String saleId) {
    return _saleService.cancelSale(saleId);
  }

  Future<OperationResult<List<Sale>>> getSales({
    bool includeCancelled = false,
  }) {
    return _saleService.getSales(
      includeCancelled: includeCancelled,
    );
  }

  Future<OperationResult<Sale>> getSaleById(String saleId) {
    return _saleService.getSaleById(saleId);
  }

  Future<OperationResult<List<Sale>>> searchSales({
    String query = '',
    SaleStatus? status,
  }) {
    return _saleService.searchSales(
      query: query,
      status: status,
    );
  }
}
