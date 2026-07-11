import 'data/repositories/in_memory_product_repository.dart';
import 'data/repositories/in_memory_sale_repository.dart';
import 'data/repositories/in_memory_user_repository.dart';
import 'data/repositories/in_memory_stock_alert_repository.dart';
import 'logic/controllers/auth_controller.dart';
import 'logic/controllers/product_controller.dart';
import 'logic/controllers/sale_controller.dart';
import 'logic/controllers/stock_alert_controller.dart';
import 'logic/observers/stock_change_notifier.dart';
import 'logic/services/auth_service.dart';
import 'logic/services/product_service.dart';
import 'logic/services/sale_service.dart';
import 'logic/services/stock_alert_service.dart';

class AppDependencies {
  AppDependencies() {
    final userRepository = InMemoryUserRepository();
    final productRepository = InMemoryProductRepository();
    final saleRepository = InMemorySaleRepository();
    final stockAlertRepository = InMemoryStockAlertRepository();
    final stockChangeNotifier = StockChangeNotifier.instance;

    final authService = AuthService(
      userRepository: userRepository,
    );

    final productService = ProductService(
      productRepository: productRepository,
    );

    final saleService = SaleService(
      saleRepository: saleRepository,
      productRepository: productRepository,
      stockChangeNotifier: stockChangeNotifier,
    );

    final stockAlertService = StockAlertService(
      stockAlertRepository: stockAlertRepository,
      productRepository: productRepository,
    );

    authController = AuthController(
      authService: authService,
    );

    productController = ProductController(
      productService: productService,
    );

    saleController = SaleController(
      saleService: saleService,
    );

    stockAlertController = StockAlertController(
      stockAlertService: stockAlertService,
    );
  }

  late final AuthController authController;
  late final ProductController productController;
  late final SaleController saleController;
  late final StockAlertController stockAlertController;
}