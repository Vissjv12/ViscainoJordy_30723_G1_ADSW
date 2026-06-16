import '../../data/models/product.dart';
import '../results/operation_result.dart';
import '../services/product_service.dart';

class ProductController {
  ProductController({
    required ProductService productService,
  }) : _productService = productService;

  final ProductService _productService;

  Future<OperationResult<Product>> registerProduct({
    required String sku,
    required String name,
    required double price,
    required int stock,
    required String category,
    required String location,
  }) {
    return _productService.registerProduct(
      sku: sku,
      name: name,
      price: price,
      stock: stock,
      category: category,
      location: location,
    );
  }

  Future<OperationResult<List<Product>>> getProducts({
    bool includeInactive = false,
  }) {
    return _productService.getProducts(
      includeInactive: includeInactive,
    );
  }

  Future<OperationResult<Product>> getProductById(
    String id,
  ) {
    return _productService.getProductById(id);
  }

  Future<OperationResult<List<Product>>> searchProducts({
    String query = '',
    String? category,
    ProductStatus? status,
    ProductSortOption sortOption =
        ProductSortOption.name,
    bool ascending = true,
  }) {
    return _productService.searchProducts(
      query: query,
      category: category,
      status: status,
      sortOption: sortOption,
      ascending: ascending,
    );
  }

  Future<OperationResult<Product>> updateProduct({
    required Product product,
  }) {
    return _productService.updateProduct(
      product: product,
    );
  }

  Future<OperationResult<Product>> deactivateProduct(
    String id,
  ) {
    return _productService.deactivateProduct(id);
  }
}