import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';
import 'package:paperboost/logic/controllers/auth_controller.dart';
import 'package:paperboost/logic/services/auth_service.dart';
import 'package:paperboost/logic/session/session_manager.dart';
import 'package:paperboost/presentation/pages/register_page.dart';

void main() {
  group('RegisterPage', () {
    late AuthController authController;

    setUp(() {
      final userRepo = InMemoryUserRepository();
      final sessionManager = SessionManager();
      final authService = AuthService(
        userRepository: userRepo,
        sessionManager: sessionManager,
      );
      authController = AuthController(authService: authService);
    });

    Widget createWidget() {
      return MaterialApp(
        home: RegisterPage(authController: authController),
      );
    }

    testWidgets('renders title "Crear Cuenta de Seguridad"', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Crear Cuenta de Seguridad'), findsOneWidget);
    });

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Tu Correo electrónico'), findsOneWidget);
      expect(find.text('Elige una Contraseña (mínimo 6 letras/números)'), findsOneWidget);
    });

    testWidgets('renders "Activar y Guardar Cuenta" button', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Activar y Guardar Cuenta'), findsOneWidget);
    });

    testWidgets('renders "Volver atrás" button', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Volver atrás'), findsOneWidget);
    });

    testWidgets('password visibility toggle', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('back button navigates back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/register',
          routes: {
            '/register': (_) => RegisterPage(authController: authController),
            '/': (_) => const Scaffold(body: Text('Login Page')),
          },
        ),
      );

      await tester.tap(find.text('Volver atrás'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('invalid email shows validation error', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Activar y Guardar Cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor, introduce un correo.'), findsOneWidget);
    });

    testWidgets('empty password shows validation error', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Activar y Guardar Cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor, introduce una contraseña.'), findsOneWidget);
    });

    testWidgets('register form with valid data shows admin exists error', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'Password123');
      await tester.pump();

      await tester.tap(find.text('Activar y Guardar Cuenta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Ya existe un usuario registrado'), findsOneWidget);
    });
  });
}
