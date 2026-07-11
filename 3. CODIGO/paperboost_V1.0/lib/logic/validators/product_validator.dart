import '../../data/models/product.dart';

class ProductValidator {
  const ProductValidator();

  static List<String> validateProduct(Product product) {
    final errors = <String>[];

    if (product.sku.trim().isEmpty) {
      errors.add('El SKU es obligatorio.');
    }

    if (product.name.trim().isEmpty) {
      errors.add('El nombre del producto es obligatorio.');
    }

    if (product.price <= 0) {
      errors.add('El precio debe ser mayor que cero.');
    }

    if (product.stock < 0) {
      errors.add('El stock no puede ser negativo.');
    }

    if (product.category.trim().isEmpty) {
      errors.add('La categoría es obligatoria.');
    }

    if (product.location.trim().isEmpty) {
      errors.add('La ubicación es obligatoria.');
    }

    return errors;
  }
}