import '../models/product.dart';
import 'product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final List<Product> _products = [];

  @override
  Future<List<Product>> findAll({
    bool includeInactive = false,
  }) async {
    final products = includeInactive
        ? List<Product>.from(_products)
        : _products
            .where((product) => product.isActive)
            .toList(growable: false);

    products.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );

    return List<Product>.unmodifiable(products);
  }

  @override
  Future<Product?> findById(String id) async {
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }

  @override
  Future<Product?> findBySku(String sku) async {
    final normalizedSku = _normalizeSku(sku);

    for (final product in _products) {
      if (_normalizeSku(product.sku) == normalizedSku) {
        return product;
      }
    }

    return null;
  }

  @override
  Future<bool> existsBySku(
    String sku, {
    String? excludingProductId,
  }) async {
    final normalizedSku = _normalizeSku(sku);

    return _products.any(
      (product) =>
          _normalizeSku(product.sku) == normalizedSku &&
          product.id != excludingProductId,
    );
  }

  @override
  Future<void> save(Product product) async {
    final duplicatedId = _products.any(
      (currentProduct) => currentProduct.id == product.id,
    );

    if (duplicatedId) {
      throw StateError(
        'Ya existe un producto con el identificador ${product.id}.',
      );
    }

    _products.add(product);
  }

  @override
  Future<void> update(Product product) async {
    final index = _products.indexWhere(
      (currentProduct) => currentProduct.id == product.id,
    );

    if (index == -1) {
      throw StateError(
        'No se encontró el producto que se desea actualizar.',
      );
    }

    _products[index] = product;
  }

  @override
  Future<void> deactivate(String id) async {
    final index = _products.indexWhere(
      (product) => product.id == id,
    );

    if (index == -1) {
      throw StateError(
        'No se encontró el producto que se desea dar de baja.',
      );
    }

    final currentProduct = _products[index];

    _products[index] = currentProduct.copyWith(
      status: ProductStatus.inactive,
    );
  }

  String _normalizeSku(String value) {
    return value.trim().toUpperCase();
  }
}