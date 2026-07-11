import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/main.dart' as app;
import 'package:paperboost/app_dependencies.dart';

void main() {
  testWidgets('PaperBoostApp renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(app.PaperBoostApp(dependencies: AppDependencies()));
    expect(find.text('PaperBoost'), findsOneWidget);
    expect(find.text('Gestión rápida para tu negocio'), findsOneWidget);
  });

  testWidgets('main() function runs without error', (WidgetTester tester) async {
    app.main();
    await tester.pump();
    expect(find.text('PaperBoost'), findsOneWidget);
    expect(find.text('Entrar sin cuenta (Recomendado)'), findsOneWidget);
  });

  testWidgets('/register route shows register page via login button', (WidgetTester tester) async {
    await tester.pumpWidget(app.PaperBoostApp(dependencies: AppDependencies()));

    await tester.tap(find.textContaining('Crear cuenta de seguridad aquí'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta de Seguridad'), findsOneWidget);
  });

  testWidgets('/home route shows after successful login', (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(app.PaperBoostApp(dependencies: AppDependencies()));

    await tester.enterText(find.byType(TextFormField).first, 'admin@paperboost.com');
    await tester.enterText(find.byType(TextFormField).last, 'Admin123*');
    await tester.pump();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Inventario PaperBoost'), findsOneWidget);
  });
}
