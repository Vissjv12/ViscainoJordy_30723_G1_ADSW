import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../data/models/stock_alert.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDeactivate,
    required this.onConfigureAlert,
    this.stockAlert,
    super.key,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onConfigureAlert;
  final StockAlert? stockAlert;

  @override
  Widget build(BuildContext context) {
    final isActive = product.status == ProductStatus.active;
    final isCritical = isActive &&
        stockAlert != null &&
        stockAlert!.isActive &&
        product.stock <= stockAlert!.minimumQuantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCritical ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (isCritical) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡STOCK CRÍTICO! Mínimo: ${stockAlert!.minimumQuantity}, Actual: ${product.stock}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: isActive ? onConfigureAlert : null,
                  icon: Icon(
                    stockAlert != null && stockAlert!.isActive
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    size: 16,
                  ),
                  label: Text(
                    stockAlert != null && stockAlert!.isActive
                        ? 'Alerta (${stockAlert!.minimumQuantity})'
                        : 'Configurar Alerta',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isActive ? onEdit : null,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      isActive ? onDeactivate : null,
                  icon: const Icon(Icons.block, size: 16),
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