import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../results/operation_result.dart';
import '../validators/product_validator.dart';

enum ProductSortOption {
  name,
  price,
  stock,
}

class ProductService {
  ProductService({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  final ProductRepository _productRepository;

  Future<OperationResult<Product>> registerProduct({
    required String sku,
    required String name,
    required double price,
    required int stock,
    required String category,
    required String location,
  }) async {
    final product = Product(
      id: _generateProductId(),
      sku: sku.trim().toUpperCase(),
      name: name.trim(),
      price: price,
      stock: stock,
      category: category.trim(),
      location: location.trim(),
    );

    final validationErrors =
        ProductValidator.validateProduct(product);

    if (validationErrors.isNotEmpty) {
      return OperationResult<Product>.failure(
        message: validationErrors.join('\n'),
      );
    }

    final duplicatedSku =
        await _productRepository.existsBySku(product.sku);

    if (duplicatedSku) {
      return OperationResult<Product>.failure(
        message:
            'Ya existe un producto registrado con el SKU ${product.sku}.',
      );
    }

    try {
      await _productRepository.save(product);

      return OperationResult<Product>.success(
        message: 'Producto registrado correctamente.',
        data: product,
      );
    } catch (error) {
      return OperationResult<Product>.failure(
        message: 'No se pudo registrar el producto: $error',
      );
    }
  }

  Future<OperationResult<List<Product>>> getProducts({
    bool includeInactive = false,
  }) async {
    try {
      final products = await _productRepository.findAll(
        includeInactive: includeInactive,
      );

      return OperationResult<List<Product>>.success(
        message: products.isEmpty
            ? 'No existen productos registrados.'
            : 'Productos consultados correctamente.',
        data: products,
      );
    } catch (error) {
      return OperationResult<List<Product>>.failure(
        message: 'No se pudo consultar el inventario: $error',
      );
    }
  }

  Future<OperationResult<Product>> getProductById(
    String id,
  ) async {
    if (id.trim().isEmpty) {
      return OperationResult<Product>.failure(
        message: 'El identificador del producto es obligatorio.',
      );
    }

    final product = await _productRepository.findById(
      id.trim(),
    );

    if (product == null) {
      return OperationResult<Product>.failure(
        message: 'Producto no encontrado.',
      );
    }

    return OperationResult<Product>.success(
      message: 'Producto encontrado.',
      data: product,
    );
  }

  Future<OperationResult<List<Product>>> searchProducts({
    String query = '',
    String? category,
    ProductStatus? status,
    ProductSortOption sortOption =
        ProductSortOption.name,
    bool ascending = true,
  }) async {
    try {
      final products = await _productRepository.findAll(
        includeInactive: true,
      );

      final normalizedQuery =
          query.trim().toLowerCase();

      final filteredProducts = products.where((product) {
        final matchesQuery =
            normalizedQuery.isEmpty ||
                product.name
                    .toLowerCase()
                    .contains(normalizedQuery) ||
                product.sku
                    .toLowerCase()
                    .contains(normalizedQuery);

        final matchesCategory =
            category == null ||
                category.trim().isEmpty ||
                product.category.toLowerCase() ==
                    category.trim().toLowerCase();

        final matchesStatus =
            status == null || product.status == status;

        return matchesQuery &&
            matchesCategory &&
            matchesStatus;
      }).toList();

      _sortProducts(
        filteredProducts,
        sortOption: sortOption,
        ascending: ascending,
      );

      return OperationResult<List<Product>>.success(
        message: filteredProducts.isEmpty
            ? 'No se encontraron productos.'
            : 'Búsqueda realizada correctamente.',
        data: filteredProducts,
      );
    } catch (error) {
      return OperationResult<List<Product>>.failure(
        message: 'No se pudo realizar la búsqueda: $error',
      );
    }
  }

  Future<OperationResult<Product>> updateProduct({
    required Product product,
  }) async {
    final currentProduct =
        await _productRepository.findById(product.id);

    if (currentProduct == null) {
      return OperationResult<Product>.failure(
        message: 'El producto que desea editar no existe.',
      );
    }

    final normalizedProduct = product.copyWith(
      sku: product.sku.trim().toUpperCase(),
      name: product.name.trim(),
      category: product.category.trim(),
      location: product.location.trim(),
    );

    final validationErrors =
        ProductValidator.validateProduct(
      normalizedProduct,
    );

    if (validationErrors.isNotEmpty) {
      return OperationResult<Product>.failure(
        message: validationErrors.join('\n'),
      );
    }

    final duplicatedSku =
        await _productRepository.existsBySku(
      normalizedProduct.sku,
      excludingProductId: normalizedProduct.id,
    );

    if (duplicatedSku) {
      return OperationResult<Product>.failure(
        message:
            'Ya existe otro producto con el SKU ${normalizedProduct.sku}.',
      );
    }

    try {
      await _productRepository.update(
        normalizedProduct,
      );

      return OperationResult<Product>.success(
        message: 'Producto actualizado correctamente.',
        data: normalizedProduct,
      );
    } catch (error) {
      return OperationResult<Product>.failure(
        message: 'No se pudo actualizar el producto: $error',
      );
    }
  }

  Future<OperationResult<Product>> deactivateProduct(
    String id,
  ) async {
    final product = await _productRepository.findById(id);

    if (product == null) {
      return OperationResult<Product>.failure(
        message:
            'El producto que desea dar de baja no existe.',
      );
    }

    if (!product.isActive) {
      return OperationResult<Product>.failure(
        message: 'El producto ya se encuentra dado de baja.',
      );
    }

    try {
      await _productRepository.deactivate(id);

      final inactiveProduct = product.copyWith(
        status: ProductStatus.inactive,
      );

      return OperationResult<Product>.success(
        message: 'Producto dado de baja exitosamente.',
        data: inactiveProduct,
      );
    } catch (error) {
      return OperationResult<Product>.failure(
        message: 'No se pudo dar de baja el producto: $error',
      );
    }
  }

  void _sortProducts(
    List<Product> products, {
    required ProductSortOption sortOption,
    required bool ascending,
  }) {
    products.sort((first, second) {
      int comparison;

      switch (sortOption) {
        case ProductSortOption.name:
          comparison = first.name
              .toLowerCase()
              .compareTo(second.name.toLowerCase());
          break;

        case ProductSortOption.price:
          comparison =
              first.price.compareTo(second.price);
          break;

        case ProductSortOption.stock:
          comparison =
              first.stock.compareTo(second.stock);
          break;
      }

      return ascending ? comparison : -comparison;
    });
  }

  String _generateProductId() {
    final timestamp =
        DateTime.now().microsecondsSinceEpoch;

    return 'PRODUCT-$timestamp';
  }
}