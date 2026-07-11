import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/models/stock_alert.dart';
import 'package:paperboost/presentation/widgets/product_card.dart';

void main() {
  group('ProductCard', () {
    const product = Product(
      id: 'PROD-001',
      sku: 'SKU-001',
      name: 'Test Product',
      price: 100.50,
      stock: 50,
      category: 'Papelería',
      location: 'A1-B2',
    );

    Widget createCard({
      required Product cardProduct,
      StockAlert? stockAlert,
      required VoidCallback onEdit,
      required VoidCallback onDeactivate,
      required VoidCallback onConfigureAlert,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product: cardProduct,
            stockAlert: stockAlert,
            onEdit: onEdit,
            onDeactivate: onDeactivate,
            onConfigureAlert: onConfigureAlert,
          ),
        ),
      );
    }

    testWidgets('renders product name, SKU, price, stock, category, location', (tester) async {
      await tester.pumpWidget(createCard(
        cardProduct: product,
        onEdit: () {},
        onDeactivate: () {},
        onConfigureAlert: () {},
      ));

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.textContaining('SKU: SKU-001'), findsOneWidget);
      expect(find.textContaining('\$100.50'), findsOneWidget);
      expect(find.textContaining('Stock: 50'), findsOneWidget);
      expect(find.text('Categoría: Papelería'), findsOneWidget);
      expect(find.text('Ubicación: A1-B2'), findsOneWidget);
    });

    testWidgets('shows "Activo" chip for active products', (tester) async {
      await tester.pumpWidget(createCard(
        cardProduct: product,
        onEdit: () {},
        onDeactivate: () {},
        onConfigureAlert: () {},
      ));

      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('shows "Inactivo" chip for inactive products', (tester) async {
      const inactiveProduct = Product(
        id: 'PROD-002',
        sku: 'SKU-002',
        name: 'Inactive Item',
        price: 25.00,
        stock: 0,
        category: 'Test',
        location: 'C3',
        status: ProductStatus.inactive,
      );

      await tester.pumpWidget(createCard(
        cardProduct: inactiveProduct,
        onEdit: () {},
        onDeactivate: () {},
        onConfigureAlert: () {},
      ));

      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('shows critical stock warning when stock alert is configured and stock is low', (tester) async {
      const criticalProduct = Product(
        id: 'PROD-003',
        sku: 'SKU-003',
        name: 'Low Stock Item',
        price: 10.00,
        stock: 3,
        category: 'Test',
        location: 'D4',
      );

      final alert = StockAlert(
        id: 'ALERT-001',
        productId: 'PROD-003',
        minimumQuantity: 5,
        isActive: true,
      );

      await tester.pumpWidget(createCard(
        cardProduct: criticalProduct,
        stockAlert: alert,
        onEdit: () {},
        onDeactivate: () {},
        onConfigureAlert: () {},
      ));

      expect(find.textContaining('STOCK CRÍTICO'), findsOneWidget);
      expect(find.textContaining('Mínimo: 5'), findsOneWidget);
    });

    testWidgets('onEdit callback is called when edit button is tapped', (tester) async {
      bool editCalled = false;

      await tester.pumpWidget(createCard(
        cardProduct: product,
        onEdit: () => editCalled = true,
        onDeactivate: () {},
        onConfigureAlert: () {},
      ));

      await tester.tap(find.text('Editar'));
      await tester.pump();
      expect(editCalled, true);
    });

    testWidgets('onDeactivate callback is called when deactivate button is tapped', (tester) async {
      bool deactivateCalled = false;

      await tester.pumpWidget(createCard(
        cardProduct: product,
        onEdit: () {},
        onDeactivate: () => deactivateCalled = true,
        onConfigureAlert: () {},
      ));

      await tester.tap(find.text('Dar de baja'));
      await tester.pump();
      expect(deactivateCalled, true);
    });

    testWidgets('onConfigureAlert callback is called when configure alert button is tapped', (tester) async {
      bool alertConfigured = false;

      await tester.pumpWidget(createCard(
        cardProduct: product,
        onEdit: () {},
        onDeactivate: () {},
        onConfigureAlert: () => alertConfigured = true,
      ));

      await tester.tap(find.text('Configurar Alerta'));
      await tester.pump();
      expect(alertConfigured, true);
    });
  });
}
