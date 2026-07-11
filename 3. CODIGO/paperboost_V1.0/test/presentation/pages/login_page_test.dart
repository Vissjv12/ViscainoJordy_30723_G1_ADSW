import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:paperboost/data/repositories/in_memory_user_repository.dart';
import 'package:paperboost/logic/controllers/auth_controller.dart';
import 'package:paperboost/logic/services/auth_service.dart';
import 'package:paperboost/logic/session/session_manager.dart';
import 'package:paperboost/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    late AuthController authController;
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      final userRepo = InMemoryUserRepository();
      final authService = AuthService(
        userRepository: userRepo,
        sessionManager: sessionManager,
      );
      authController = AuthController(authService: authService);
    });

    Widget createWidget() {
      return MaterialApp(
        home: LoginPage(authController: authController),
      );
    }

    testWidgets('renders PaperBoost title', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('PaperBoost'), findsOneWidget);
    });

    testWidgets('renders "Entrar sin cuenta" button', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Entrar sin cuenta (Recomendado)'), findsOneWidget);
    });

    testWidgets('renders "Iniciar sesión" button', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('tapping visibility toggle toggles password obscure', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('tapping register button navigates to register', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (_) => LoginPage(authController: authController),
            '/register': (_) => const Scaffold(body: Text('Register Page')),
          },
        ),
      );

      await tester.tap(find.textContaining('Crear cuenta de seguridad aquí'));
      await tester.pumpAndSettle();

      expect(find.text('Register Page'), findsOneWidget);
    });

    testWidgets('form submission with invalid data shows validation errors', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor, ingrese su correo.'), findsOneWidget);
      expect(find.text('Por favor, ingrese su contraseña.'), findsOneWidget);
    });

    testWidgets('tapping "Entrar sin cuenta" triggers loginAsGuest and navigates to home', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (_) => LoginPage(authController: authController),
            '/home': (_) => const Scaffold(body: Text('Home Page')),
          },
        ),
      );

      await tester.tap(find.text('Entrar sin cuenta (Recomendado)'));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('login with admin credentials shows success snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (_) => LoginPage(authController: authController),
            '/home': (_) => const Scaffold(body: Text('Home Page')),
          },
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'admin@paperboost.com');
      await tester.enterText(find.byType(TextFormField).last, 'Admin123*');
      await tester.pump();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Inicio de sesión correcto.'), findsOneWidget);
    });

    testWidgets('login with wrong credentials shows error snackbar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'wrong@email.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
      await tester.pump();

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('incorrectos'), findsOneWidget);
    });
  });
}
