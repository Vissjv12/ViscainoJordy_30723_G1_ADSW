import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/models/product.dart';
import 'package:paperboost/data/repositories/in_memory_product_repository.dart';
import 'package:paperboost/logic/controllers/product_controller.dart';
import 'package:paperboost/logic/services/product_service.dart';
import 'package:paperboost/presentation/pages/product_form_page.dart';

Widget createTestWidget({Product? product}) {
  final repo = InMemoryProductRepository();
  final service = ProductService(productRepository: repo);
  final controller = ProductController(productService: service);
  return MaterialApp(
    home: ProductFormPage(
      productController: controller,
      product: product,
    ),
  );
}

void main() {
  group('ProductFormPage', () {
    late ProductController productController;

    setUp(() {
      final productRepo = InMemoryProductRepository();
      final productService = ProductService(productRepository: productRepo);
      productController = ProductController(productService: productService);
    });

    testWidgets('shows "Registrar producto" title when creating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductFormPage(
            productController: productController,
          ),
        ),
      );

      expect(find.text('Registrar producto'), findsOneWidget);
    });

    testWidgets('shows "Editar producto" title when editing', (tester) async {
      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Test',
        price: 10.00,
        stock: 5,
        category: 'Cat',
        location: 'Loc',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductFormPage(
            productController: productController,
            product: product,
          ),
        ),
      );

      expect(find.text('Editar producto'), findsOneWidget);
    });

    testWidgets('has form fields for SKU, name, price, stock, category, location', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductFormPage(
            productController: productController,
          ),
        ),
      );

      expect(find.text('SKU'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Precio'), findsOneWidget);
      expect(find.text('Stock'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Ubicación'), findsOneWidget);
    });

    testWidgets('has Cancel and Save buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductFormPage(
            productController: productController,
          ),
        ),
      );

      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('filling form and tapping save calls registerProduct', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'SKU-001');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Product');
      await tester.enterText(find.byType(TextFormField).at(2), '99.99');
      await tester.enterText(find.byType(TextFormField).at(3), '10');
      await tester.enterText(find.byType(TextFormField).at(4), 'Category');
      await tester.enterText(find.byType(TextFormField).at(5), 'Location');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormPage), findsNothing);
    });

    testWidgets('pre-fills fields with product data', (tester) async {
      const product = Product(
        id: 'PROD-001',
        sku: 'SKU-001',
        name: 'Test Product',
        price: 99.99,
        stock: 10,
        category: 'Category',
        location: 'Location',
      );

      await tester.pumpWidget(createTestWidget(product: product));

      expect(find.text('SKU-001'), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('99.99'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('El SKU es obligatorio.'), findsOneWidget);
      expect(find.text('El nombre es obligatorio.'), findsOneWidget);
      expect(find.text('Ingrese un precio mayor que cero.'), findsOneWidget);
      expect(find.text('Ingrese un stock válido.'), findsOneWidget);
      expect(find.text('La categoría es obligatorio.'), findsOneWidget);
      expect(find.text('La ubicación es obligatorio.'), findsOneWidget);
    });

    testWidgets('shows error for invalid price', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'SKU-001');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Product');
      await tester.enterText(find.byType(TextFormField).at(2), 'invalid');
      await tester.enterText(find.byType(TextFormField).at(3), '10');
      await tester.enterText(find.byType(TextFormField).at(4), 'Category');
      await tester.enterText(find.byType(TextFormField).at(5), 'Location');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese un precio mayor que cero.'), findsOneWidget);
    });

    testWidgets('shows error for invalid stock', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'SKU-001');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Product');
      await tester.enterText(find.byType(TextFormField).at(2), '99.99');
      await tester.enterText(find.byType(TextFormField).at(3), 'invalid');
      await tester.enterText(find.byType(TextFormField).at(4), 'Category');
      await tester.enterText(find.byType(TextFormField).at(5), 'Location');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese un stock válido.'), findsOneWidget);
    });

    testWidgets('tapping Cancel pops the page', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormPage), findsNothing);
    });

    testWidgets('update product in edit mode saves successfully', (tester) async {
      final repo = InMemoryProductRepository();
      final service = ProductService(productRepository: repo);
      final controller = ProductController(productService: service);

      final result = await service.registerProduct(
        sku: 'SKU-001', name: 'Test', price: 100, stock: 10,
        category: 'Cat', location: 'A1',
      );
      final product = result.data!;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
        home: ProductFormPage(
          productController: controller,
          product: product,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(1), 'Updated Name');
      await tester.pump();

      await tester.ensureVisible(find.text('Guardar'));
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ProductFormPage), findsNothing);
    });

    testWidgets('update product with duplicate SKU shows error snackbar', (tester) async {
      final repo = InMemoryProductRepository();
      final service = ProductService(productRepository: repo);
      final controller = ProductController(productService: service);

      await service.registerProduct(
        sku: 'SKU-001', name: 'Existing', price: 50, stock: 5,
        category: 'Cat', location: 'A1',
      );
      final result2 = await service.registerProduct(
        sku: 'SKU-002', name: 'To Edit', price: 200, stock: 3,
        category: 'Cat', location: 'A2',
      );
      final product2 = result2.data!;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
        home: ProductFormPage(
          productController: controller,
          product: product2,
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'SKU-001');
      await tester.pump();

      await tester.ensureVisible(find.text('Guardar'));
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Ya existe otro producto'), findsOneWidget);
    });
  });
}
