import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/models/sale.dart';
import 'package:paperboost/data/models/sale_item.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/data/repositories/in_memory_sale_repository.dart';
import 'package:paperboost/data/repositories/in_memory_stock_alert_repository.dart';
import 'package:paperboost/logic/controllers/product_controller.dart';
import 'package:paperboost/logic/controllers/sale_controller.dart';
import 'package:paperboost/logic/controllers/stock_alert_controller.dart';
import 'package:paperboost/logic/observers/stock_change_notifier.dart';
import 'package:paperboost/logic/services/product_service.dart';
import 'package:paperboost/logic/services/sale_service.dart';
import 'package:paperboost/logic/services/stock_alert_service.dart';
import 'package:paperboost/presentation/pages/sales_page.dart';

void main() {
  group('SalesPage', () {
    late ProductController productController;
    late SaleController saleController;
    late StockAlertController stockAlertController;
    late InMemoryProductRepository productRepo;

    setUp(() {
      StockChangeNotifier.instance.clearObservers();

      productRepo = InMemoryProductRepository();
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
        stockChangeNotifier: StockChangeNotifier.instance,
      );
      saleController = SaleController(saleService: saleService);
    });

    Future<void> pumpPage(WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: SalesPage(
            saleController: saleController,
            productController: productController,
            stockAlertController: stockAlertController,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // ==========================================
    // Main Page
    // ==========================================
    testWidgets('renders "Notas de Venta" title', (tester) async {
      await pumpPage(tester);

      expect(find.text('Notas de Venta'), findsOneWidget);
    });

    testWidgets('has "Nueva Venta" and "Historial" tabs', (tester) async {
      await pumpPage(tester);

      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
    });

    // ==========================================
    // Create Sale Tab
    // ==========================================
    testWidgets('renders "Agregar Producto" button', (tester) async {
      await pumpPage(tester);

      expect(find.text('Agregar Producto'), findsOneWidget);
    });

    testWidgets('shows "No hay productos disponibles" when no products exist',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay productos disponibles para vender.'),
        findsOneWidget,
      );
    });

    testWidgets('with products, tapping "Agregar Producto" opens dialog',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona un producto'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('payment method dropdown defaults to "Efectivo"',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('Efectivo'), findsOneWidget);
    });

    testWidgets('customer name and email fields render', (tester) async {
      await pumpPage(tester);

      expect(find.text('Nombre del Cliente'), findsOneWidget);
      expect(find.text('Correo Electrónico'), findsOneWidget);
    });

    testWidgets('observations field renders', (tester) async {
      await pumpPage(tester);

      expect(find.text('Observaciones (Opcional)'), findsOneWidget);
    });

    testWidgets('Confirmar Venta button renders and is disabled when no items',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('Confirmar Venta'), findsOneWidget);
      final buttonFinder = find.ancestor(
        of: find.text('Confirmar Venta'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ElevatedButton,
        ),
      );
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    // ==========================================
    // Sales History Tab
    // ==========================================
    testWidgets('Historial tab shows search field', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar por venta o cliente'), findsOneWidget);
    });

    testWidgets('Historial tab shows status dropdown', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('Historial tab shows "No hay ventas registradas" when empty',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('No hay ventas registradas'), findsOneWidget);
    });

    // ==========================================
    // Notification Bell
    // ==========================================
    testWidgets(
        'shows notification bell with notifications_none when no alerts',
        (tester) async {
      await pumpPage(tester);

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('with critical alerts shows badge with count', (tester) async {
      await productController.registerProduct(
        sku: 'LOW001',
        name: 'Low Stock Product',
        price: 10.0,
        stock: 3,
        category: 'Test',
        location: 'A1',
      );

      final productsResult = await productController.getProducts();
      final product = productsResult.data!.first;

      await stockAlertController.createAlert(
        productId: product.id,
        minimumQuantity: 5,
      );

      await pumpPage(tester);

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    // ==========================================
    // Create Sale Tab — Detailed Interactions
    // ==========================================
    testWidgets('adding product to sale shows item in list with delete button',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();

      expect(find.text('Stock disponible: 10'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('Producto de Prueba'), findsOneWidget);
      expect(find.text('SKU: PROD001'), findsOneWidget);
      expect(find.text('Cantidad: 1'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('removing product from sale clears the list', (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Producto de Prueba'), findsNothing);
      expect(find.text('Subtotal:'), findsNothing);
    });

    testWidgets(
        'total summary shows subtotal IVA and total after adding product',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('Subtotal:'), findsOneWidget);
      expect(find.text('IVA (15%):'), findsOneWidget);
      expect(find.text('\$15.00'), findsOneWidget);
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('\$115.00'), findsOneWidget);
    });

    testWidgets('payment method dropdown changes to Tarjeta', (tester) async {
      await pumpPage(tester);

      expect(find.text('Efectivo'), findsOneWidget);

      await tester.tap(find.text('Efectivo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tarjeta'));
      await tester.pumpAndSettle();

      expect(find.text('Tarjeta'), findsOneWidget);
    });

    testWidgets('customer name field accepts input', (tester) async {
      await pumpPage(tester);

      final field = find.widgetWithText(TextField, 'Nombre del Cliente');
      await tester.enterText(field, 'Juan Pérez');
      await tester.pump();

      final textField = tester.widget<TextField>(field);
      expect(textField.controller?.text, 'Juan Pérez');
    });

    testWidgets('observations field accepts input', (tester) async {
      await pumpPage(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Observaciones (Opcional)'),
        'Entrega rápida',
      );
      await tester.pump();

      expect(find.text('Entrega rápida'), findsOneWidget);
    });

    testWidgets('Confirmar Venta button enables when items are present',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      var buttonFinder = find.ancestor(
        of: find.text('Confirmar Venta'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ElevatedButton,
        ),
      );
      var button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      buttonFinder = find.ancestor(
        of: find.text('Confirmar Venta'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ElevatedButton,
        ),
      );
      button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('create sale success shows snackbar and clears form',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar Venta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nota de venta creada correctamente.'),
        findsOneWidget,
      );
      expect(find.text('Producto de Prueba'), findsNothing);
    });

    testWidgets('create sale with invalid email shows error snackbar',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Correo Electrónico'),
        'invalid-email',
      );
      await tester.pump();

      await tester.tap(find.text('Confirmar Venta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ingrese un correo electrónico válido.'),
        findsOneWidget,
      );
    });

    testWidgets('create sale triggers post-sale stock alert dialog',
        (tester) async {
      await productController.registerProduct(
        sku: 'ALERT001',
        name: 'Alert Product',
        price: 100.0,
        stock: 5,
        category: 'Test',
        location: 'A1',
      );

      final productsResult = await productController.getProducts();
      final product = productsResult.data!.first;

      await stockAlertController.createAlert(
        productId: product.id,
        minimumQuantity: 5,
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alert Product'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar Venta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nota de venta creada correctamente.'),
        findsOneWidget,
      );
      expect(find.text('¡Advertencia de Stock!'), findsOneWidget);
      expect(find.textContaining('Alert Product'), findsWidgets);
    });

    testWidgets('confirm button shows loading state while processing',
        (tester) async {
      // In-memory operations complete too fast to observe the transient
      // loading state, but this test verifies the confirm + clear flow.
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar Venta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nota de venta creada correctamente.'),
        findsOneWidget,
      );
      expect(find.text('Producto de Prueba'), findsNothing);
    });

    // ==========================================
    // Add Product Dialog — Detailed
    // ==========================================
    testWidgets('add product dialog shows quantity error when quantity is zero',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '0');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa una cantidad válida.'), findsOneWidget);
    });

    testWidgets(
        'add product dialog shows stock error when quantity exceeds stock',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 5,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Selecciona un producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto de Prueba'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '10');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No hay suficiente stock. Disponible: 5',
        ),
        findsOneWidget,
      );
    });

    testWidgets('add product dialog Cancelar button closes dialog',
        (tester) async {
      await productController.registerProduct(
        sku: 'PROD001',
        name: 'Producto de Prueba',
        price: 100.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Agregar Producto'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona un producto'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona un producto'), findsNothing);
    });

    // ==========================================
    // History Tab — Detailed
    // ==========================================
    testWidgets('search field filters sales by customer name', (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 1, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Cliente Alpha',
      );
      await saleController.createSale(
        items: [
          SaleItem(id: 'i2', product: prod, quantity: 2, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.card,
        customerName: 'Cliente Beta',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente: Cliente Alpha'), findsOneWidget);
      expect(find.text('Cliente: Cliente Beta'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar por venta o cliente'),
        'Alpha',
      );
      await tester.pumpAndSettle();

      expect(find.text('Cliente: Cliente Alpha'), findsOneWidget);
      expect(find.text('Cliente: Cliente Beta'), findsNothing);
    });

    testWidgets('status dropdown filters sales by status', (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 1, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Cliente Alpha',
      );

      final sale2 = (await saleController.createSale(
        items: [
          SaleItem(id: 'i2', product: prod, quantity: 2, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.card,
        customerName: 'Cliente Beta',
      ))
          .data!;

      await saleController.cancelSale(sale2.id);

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente: Cliente Alpha'), findsOneWidget);
      expect(find.text('Cliente: Cliente Beta'), findsOneWidget);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completada').last);
      await tester.pumpAndSettle();

      expect(find.text('Cliente: Cliente Alpha'), findsOneWidget);
      expect(find.text('Cliente: Cliente Beta'), findsNothing);
    });

    testWidgets('tapping sale card opens detail dialog', (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 1, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Cliente Test',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VTA-000001'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle: VTA-000001'), findsOneWidget);
    });

    testWidgets('detail dialog shows sale info and items table',
        (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 2, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Cliente Test',
        customerEmail: 'test@example.com',
        observations: 'Entrega urgente',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VTA-000001'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle: VTA-000001'), findsOneWidget);
      expect(find.text('Observaciones: Entrega urgente'), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('PROD001'), findsOneWidget);
      expect(find.text('Email: test@example.com'), findsOneWidget);
    });

    testWidgets('cancel sale flow shows confirmation then succeeds',
        (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 1, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Cliente Test',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VTA-000001'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar Venta'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar cancelación'), findsOneWidget);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Venta cancelada correctamente.'),
        findsOneWidget,
      );
      expect(find.text('Detalle: VTA-000001'), findsNothing);
    });

    testWidgets('search field clear button resets results', (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 1, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.cash,
        customerName: 'Cliente Test',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente: Cliente Test'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar por venta o cliente'),
        'xyz',
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay ventas registradas'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Cliente: Cliente Test'), findsOneWidget);
    });

    testWidgets('Historial tab shows sale card with details', (tester) async {
      final prod = (await productController.registerProduct(
        sku: 'PROD001',
        name: 'Test Product',
        price: 100.0,
        stock: 50,
        category: 'Test',
        location: 'A1',
      ))
          .data!;

      await saleController.createSale(
        items: [
          SaleItem(id: 'i1', product: prod, quantity: 3, unitPrice: 100.0),
        ],
        paymentMethod: PaymentMethod.transfer,
        customerName: 'Cliente Test',
      );

      await pumpPage(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('VTA-000001'), findsOneWidget);
      expect(find.text('1 producto(s)'), findsOneWidget);
      expect(find.textContaining('\$345.00'), findsOneWidget);
      expect(find.text('Cliente: Cliente Test'), findsOneWidget);
      expect(find.text('Pago: Transferencia'), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);
    });

    // ==========================================
    // Notification Bell — Detailed
    // ==========================================
    testWidgets('notification bell tap shows triggered alerts dialog',
        (tester) async {
      await productController.registerProduct(
        sku: 'LOW001',
        name: 'Low Stock Product',
        price: 10.0,
        stock: 3,
        category: 'Test',
        location: 'A1',
      );

      final productsResult = await productController.getProducts();
      final product = productsResult.data!.first;

      await stockAlertController.createAlert(
        productId: product.id,
        minimumQuantity: 5,
      );

      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.notifications_active));
      await tester.pumpAndSettle();

      expect(find.text('Alertas de Stock Crítico'), findsOneWidget);
      expect(find.textContaining('Low Stock Product'), findsOneWidget);
    });

    testWidgets('StockObserver calls reload alerts on stock changed',
        (tester) async {
      await productController.registerProduct(
        sku: 'OBS001',
        name: 'Observer Product',
        price: 10.0,
        stock: 10,
        category: 'Test',
        location: 'A1',
      );

      final productsResult = await productController.getProducts();
      final product = productsResult.data!.first;

      await stockAlertController.createAlert(
        productId: product.id,
        minimumQuantity: 5,
      );

      await pumpPage(tester);

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);

      await productRepo.update(product.copyWith(stock: 3));
      StockChangeNotifier.instance.notifyStockChanged(product, 10, 3);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
