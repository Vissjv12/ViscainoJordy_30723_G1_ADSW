import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_sale_repository.dart';
import 'package:paperboost/data/repositories/in_memory_stock_alert_repository.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';
import 'package:paperboost/logic/controllers/auth_controller.dart';
import 'package:paperboost/logic/controllers/product_controller.dart';
import 'package:paperboost/logic/controllers/sale_controller.dart';
import 'package:paperboost/logic/controllers/stock_alert_controller.dart';
import 'package:paperboost/logic/observers/stock_change_notifier.dart';
import 'package:paperboost/logic/services/auth_service.dart';
import 'package:paperboost/logic/services/product_service.dart';
import 'package:paperboost/logic/services/sale_service.dart';
import 'package:paperboost/logic/services/stock_alert_service.dart';
import 'package:paperboost/logic/session/session_manager.dart';
import 'package:paperboost/presentation/pages/home_shell.dart';

void main() {
  group('HomeShell', () {
    late AuthController authController;
    late ProductController productController;
    late SaleController saleController;
    late StockAlertController stockAlertController;

    setUp(() {
      StockChangeNotifier.instance.clearObservers();

      final userRepo = InMemoryUserRepository();
      final sessionManager = SessionManager();
      final authService = AuthService(
        userRepository: userRepo,
        sessionManager: sessionManager,
      );
      authController = AuthController(authService: authService);

      final productRepo = InMemoryProductRepository();
      final productService = ProductService(productRepository: productRepo);
      productController = ProductController(productService: productService);

      final stockAlertRepo = InMemoryStockAlertRepository();
      final stockAlertService = StockAlertService(
        stockAlertRepository: stockAlertRepo,
        productRepository: productRepo,
      );
      stockAlertController = StockAlertController(
        stockAlertService: stockAlertService,
      );

      final saleRepo = InMemorySaleRepository();
      final saleService = SaleService(
        saleRepository: saleRepo,
        productRepository: productRepo,
      );
      saleController = SaleController(saleService: saleService);
    });

    Future<void> pumpShell(WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            authController: authController,
            productController: productController,
            saleController: saleController,
            stockAlertController: stockAlertController,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders bottom navigation with Inventory and Sales tabs', (tester) async {
      await pumpShell(tester);

      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Ventas'), findsOneWidget);
    });

    testWidgets('shows InventoryPage by default with "Inventario PaperBoost" title', (tester) async {
      await pumpShell(tester);

      expect(find.text('Inventario PaperBoost'), findsOneWidget);
    });

    testWidgets('tapping sales tab switches to sales view', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Ventas'));
      await tester.pumpAndSettle();

      expect(find.text('Notas de Venta'), findsOneWidget);
    });

    testWidgets('tapping Ventas tab switches to sales view at index 1', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Ventas'));
      await tester.pumpAndSettle();

      expect(find.text('Notas de Venta'), findsOneWidget);
    });

    testWidgets('logout shows snackbar and navigates to login', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/home',
          routes: {
            '/home': (_) => HomeShell(
              authController: authController,
              productController: productController,
              saleController: saleController,
              stockAlertController: stockAlertController,
            ),
            '/login': (_) => const Scaffold(body: Text('Login Page')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('sesión'), findsOneWidget);
      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
