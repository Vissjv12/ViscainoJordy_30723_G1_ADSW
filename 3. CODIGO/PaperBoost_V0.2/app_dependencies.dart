import 'data/repositories/in_memory_product_repository.dart';
import 'data/repositories/in_memory_user_repository.dart';
import 'logic/controllers/auth_controller.dart';
import 'logic/controllers/product_controller.dart';
import 'logic/services/auth_service.dart';
import 'logic/services/product_service.dart';

class AppDependencies {
  AppDependencies() {
    final userRepository = InMemoryUserRepository();
    final productRepository = InMemoryProductRepository();

    final authService = AuthService(
      userRepository: userRepository,
    );

    final productService = ProductService(
      productRepository: productRepository,
    );

    authController = AuthController(
      authService: authService,
    );

    productController = ProductController(
      productService: productService,
    );
  }

  late final AuthController authController;
  late final ProductController productController;
}