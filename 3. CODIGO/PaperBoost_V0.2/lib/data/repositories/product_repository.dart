import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> findAll({
    bool includeInactive = false,
  });

  Future<Product?> findById(String id);

  Future<Product?> findBySku(String sku);

  Future<void> save(Product product);

  Future<void> update(Product product);

  Future<void> deactivate(String id);

  Future<bool> existsBySku(
    String sku, {
    String? excludingProductId,
  });
}