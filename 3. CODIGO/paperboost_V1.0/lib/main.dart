import 'package:flutter/material.dart';
import 'presentation/pages/register_page.dart';
import 'app_dependencies.dart';
import 'presentation/pages/home_shell.dart';
import 'presentation/pages/login_page.dart';

void main() {
  final dependencies = AppDependencies();

  runApp(
    PaperBoostApp(
      dependencies: dependencies,
    ),
  );
}

class PaperBoostApp extends StatelessWidget {
  const PaperBoostApp({
    required this.dependencies,
    super.key,
  });

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaperBoost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B87),
        ),
        useMaterial3: true,
        inputDecorationTheme:
            const InputDecorationTheme(
          filled: true,
        ),
      ),
      initialRoute: '/login',
      routes: {
  '/login': (_) => LoginPage(authController: dependencies.authController),
  '/register': (_) => RegisterPage(authController: dependencies.authController), // <-- 2. Registrar la ruta nueva
  '/home': (_) => HomeShell(
        authController: dependencies.authController,
        productController: dependencies.productController,
        saleController: dependencies.saleController,
        stockAlertController: dependencies.stockAlertController,
      ),
},
    );
  }
}