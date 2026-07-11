import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_stock_alert_repository.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';
import 'package:paperboost/logic/controllers/auth_controller.dart';
import 'package:paperboost/logic/controllers/product_controller.dart';
import 'package:paperboost/logic/controllers/stock_alert_controller.dart';
import 'package:paperboost/logic/observers/stock_change_notifier.dart';
import 'package:paperboost/logic/services/auth_service.dart';
import 'package:paperboost/logic/services/product_service.dart';
import 'package:paperboost/logic/services/stock_alert_service.dart';
import 'package:paperboost/logic/session/session_manager.dart';
import 'package:paperboost/presentation/pages/inventory_page.dart';
import 'package:paperboost/presentation/widgets/product_card.dart';

void main() {
  group('InventoryPage', () {
    late AuthController authController;
    late ProductController productController;
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
    });

    /// Desktop layout (isMobile=false, columns=2 GridView).
    /// Product card buttons may be off-screen due to overflow.
    Future<void> pumpPage(WidgetTester tester, {VoidCallback? onLogout}) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: InventoryPage(
            authController: authController,
            productController: productController,
            stockAlertController: stockAlertController,
            onLogout: onLogout,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Narrower desktop width so LayoutBuilder picks columns=1 → ListView,
    /// which is scrollable and avoids GridView overflow. Still desktop (width >= 600).
    Future<void> pumpListViewPage(WidgetTester tester, {VoidCallback? onLogout}) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(650, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: InventoryPage(
            authController: authController,
            productController: productController,
            stockAlertController: stockAlertController,
            onLogout: onLogout,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Mobile layout (isMobile=true).
    Future<void> pumpMobilePage(WidgetTester tester, {VoidCallback? onLogout}) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: InventoryPage(
            authController: authController,
            productController: productController,
            stockAlertController: stockAlertController,
            onLogout: onLogout,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // ============================================================
    // LAYOUT & BASICS (existing tests preserved)
    // ============================================================

    testWidgets('renders "Inventario PaperBoost" title', (tester) async {
      await pumpPage(tester);
      expect(find.text('Inventario PaperBoost'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await pumpPage(tester);
      expect(find.text('Buscar por nombre o SKU'), findsOneWidget);
    });

    testWidgets('renders category, status, sort dropdowns', (tester) async {
      await pumpPage(tester);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Activos'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
    });

    testWidgets('shows "No se encontraron productos" when empty', (tester) async {
      await pumpPage(tester);
      expect(find.text('No se encontraron productos.'), findsOneWidget);
    });

    testWidgets('shows floating action button for register product', (tester) async {
      await pumpPage(tester);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // ============================================================
    // LOADING STATE
    // ============================================================

    testWidgets('hides loading indicator after data loaded', (tester) async {
      await pumpPage(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // ============================================================
    // PRODUCT RENDERING
    // ============================================================

    testWidgets('renders products when data loaded', (tester) async {
      await tester.runAsync(() => productController.registerProduct(
        sku: 'SKU-001',
        name: 'Test Product',
        price: 10.0,
        stock: 5,
        category: 'Test Cat',
        location: 'Test Loc',
      ));

      await pumpListViewPage(tester);

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.byType(ProductCard), findsOneWidget);
    });

    // ============================================================
    // TAB SWITCHING
    // ============================================================

    testWidgets('tab switching to Crítico hides non-critical products',
        (tester) async {
      await tester.runAsync(() => productController.registerProduct(
        sku: 'SKU-TAB',
        name: 'Tab Product',
        price: 10.0,
        stock: 5,
        category: 'Tab Cat',
        location: 'Tab Loc',
      ));

      await pumpListViewPage(tester);

      expect(find.text('Tab Product'), findsOneWidget);

      await tester.tap(find.text('Crítico'));
      await tester.pumpAndSettle();

      expect(find.text('Tab Product'), findsNothing);
      expect(find.text('No se encontraron productos.'), findsOneWidget);
    });

    testWidgets('critical tab shows products with critical stock',
        (tester) async {
      late String productId;
      await tester.runAsync(() async {
        final result = await productController.registerProduct(
          sku: 'SKU-CRIT',
          name: 'Critical Product',
          price: 10.0,
          stock: 3,
          category: 'Crit Cat',
          location: 'Crit Loc',
        );
        productId = result.data!.id;
        await stockAlertController.createAlert(
          productId: productId,
          minimumQuantity: 10,
        );
      });

      await pumpListViewPage(tester);

      expect(find.text('Critical Product'), findsOneWidget);

      await tester.tap(find.text('Crítico'));
      await tester.pumpAndSettle();

      expect(find.text('Critical Product'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsWidgets);
    });

    // ============================================================
    // NOTIFICATION BELL
    // ============================================================

    testWidgets('notification bell without critical alerts', (tester) async {
      await pumpPage(tester);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('notification bell with critical alerts', (tester) async {
      await tester.runAsync(() async {
        final result = await productController.registerProduct(
          sku: 'SKU-BELL',
          name: 'Bell Product',
          price: 10.0,
          stock: 3,
          category: 'Bell Cat',
          location: 'Bell Loc',
        );
        await stockAlertController.createAlert(
          productId: result.data!.id,
          minimumQuantity: 10,
        );
      });

      await pumpListViewPage(tester);

      expect(find.byIcon(Icons.notifications_active), findsWidgets);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('notification bell tap shows triggered alerts dialog',
        (tester) async {
      await tester.runAsync(() async {
        final result = await productController.registerProduct(
          sku: 'SKU-BELL2',
          name: 'Bell Critical',
          price: 10.0,
          stock: 2,
          category: 'Bell Cat',
          location: 'Bell Loc',
        );
        await stockAlertController.createAlert(
          productId: result.data!.id,
          minimumQuantity: 10,
        );
      });

      await pumpListViewPage(tester);

      final badge = find.byType(Badge);
      final bellIcon = find.descendant(
        of: badge,
        matching: find.byIcon(Icons.notifications_active),
      );
      await tester.tap(bellIcon);
      await tester.pumpAndSettle();

      expect(find.text('Alertas de Stock Crítico'), findsOneWidget);
      expect(find.text('Cerrar'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
    });

    // ============================================================
    // DEACTIVATE CONFIRMATION DIALOG
    // ============================================================

    testWidgets('deactivate button shows confirmation dialog', (tester) async {
      await tester.runAsync(() => productController.registerProduct(
        sku: 'SKU-DEACT',
        name: 'Deactivate Test',
        price: 10.0,
        stock: 5,
        category: 'Deact Cat',
        location: 'Deact Loc',
      ));

      await pumpListViewPage(tester);

      await tester.ensureVisible(find.text('Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dar de baja'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar baja'), findsOneWidget);
      expect(
        find.text('¿Desea dar de baja el producto "Deactivate Test"?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar baja'), findsNothing);
    });

    // ============================================================
    // CONFIGURE ALERT DIALOG
    // ============================================================

    testWidgets('configure alert dialog opens', (tester) async {
      await tester.runAsync(() => productController.registerProduct(
        sku: 'SKU-CONF',
        name: 'Conf Product',
        price: 10.0,
        stock: 5,
        category: 'Conf Cat',
        location: 'Conf Loc',
      ));

      await pumpListViewPage(tester);

      await tester.ensureVisible(find.text('Configurar Alerta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Configurar Alerta'));
      await tester.pumpAndSettle();

      expect(find.text('Configurar Alerta - Conf Product'), findsOneWidget);
      expect(find.text('Cantidad Mínima'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Configurar Alerta - Conf Product'), findsNothing);
    });

    // ============================================================
    // QUICK ACTIONS (DESKTOP vs MOBILE)
    // ============================================================

    testWidgets('quick actions card appears on desktop', (tester) async {
      await pumpPage(tester);
      expect(find.text('Acciones rápidas'), findsOneWidget);
      expect(find.text('Nueva venta'), findsOneWidget);
    });

    testWidgets('quick actions card not present on mobile', (tester) async {
      await pumpMobilePage(tester);
      expect(find.text('Acciones rápidas'), findsNothing);
    });

    // ============================================================
    // FAB → PRODUCT FORM NAVIGATION
    // ============================================================

    testWidgets('FAB navigates to product form page on mobile', (tester) async {
      await pumpMobilePage(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Registrar producto'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('FAB navigates to product form page on desktop', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Registrar producto'), findsWidgets);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    // ============================================================
    // LOGOUT
    // ============================================================

    testWidgets('logout icon button on desktop calls onLogout',
        (tester) async {
      bool logoutCalled = false;

      await pumpPage(
        tester,
        onLogout: () {
          logoutCalled = true;
        },
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    // ============================================================
    // LOADING STATE
    // ============================================================

    testWidgets('loading indicator shown during initial load', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: InventoryPage(
            authController: authController,
            productController: productController,
            stockAlertController: stockAlertController,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ============================================================
    // SEARCH FIELD CLEAR
    // ============================================================

    testWidgets('search field clear button clears text and reloads', (tester) async {
      await pumpPage(tester);

      final searchField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.labelText == 'Buscar por nombre o SKU',
      );
      await tester.enterText(searchField, 'Searchable');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
    });

    // ============================================================
    // MOBILE LAYOUT
    // ============================================================

    testWidgets('mobile layout renders without errors', (tester) async {
      await pumpMobilePage(tester);
      expect(find.text('Buscar por nombre o SKU'), findsOneWidget);
    });

    // ============================================================
    // PRODUCT CARD DETAILS
    // ============================================================

    testWidgets('product card shows price and stock', (tester) async {
      await tester.runAsync(() => productController.registerProduct(
        sku: 'SKU-PRS', name: 'PriceStock', price: 25.50, stock: 8,
        category: 'Cat', location: 'Loc',
      ));

      await pumpListViewPage(tester);

      expect(find.textContaining('\$'), findsWidgets);
      expect(find.textContaining('Stock:'), findsWidgets);
    });
  });
}
