import 'package:flutter/material.dart';

import '../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDeactivate,
    super.key,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final isActive = product.status == ProductStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    isActive ? 'Activo' : 'Inactivo',
                  ),
                  avatar: Icon(
                    isActive
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('SKU: ${product.sku}'),
            Text(
              'Precio: \$${product.price.toStringAsFixed(2)}',
            ),
            Text('Stock: ${product.stock}'),
            Text('Categoría: ${product.category}'),
            Text('Ubicación: ${product.location}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: isActive ? onEdit : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed:
                      isActive ? onDeactivate : null,
                  icon: const Icon(Icons.block),
                  label: const Text('Dar de baja'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}