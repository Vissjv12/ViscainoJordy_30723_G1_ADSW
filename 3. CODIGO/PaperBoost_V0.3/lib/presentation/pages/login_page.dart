import 'package:flutter/material.dart';
import '../../logic/controllers/auth_controller.dart';
import 'register_page.dart'; // Importamos la nueva página de registro

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.authController,
    super.key,
  });

  final AuthController authController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Los campos ahora inician vacíos para producción
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Proceso tradicional de inicio de sesión
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await widget.authController.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  /// Proceso rápido: Entrar como invitado (Sin fricciones)
  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
    });

    final result = await widget.authController.loginAsGuest();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PaperBoost',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestión rápida para tu negocio',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Botón Principal: Entrar sin cuenta (Acceso Inmediato)
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Más alto para que sea fácil de presionar por adultos mayores
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginAsGuest,
                        icon: const Icon(Icons.flash_on, size: 26),
                        label: const Text(
                          'Entrar sin cuenta (Recomendado)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('O inicia sesión si tienes cuenta'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingrese su correo.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingrese su contraseña.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _login,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: Text(_isLoading ? 'Validando...' : 'Iniciar sesión'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Botón Opcional: Crear cuenta de seguridad
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/register');
                            },
                      child: const Text(
                        '¿Quieres proteger tu app con contraseña?\nCrear cuenta de seguridad aquí',
                        textAlign: TextAlign.center,
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}