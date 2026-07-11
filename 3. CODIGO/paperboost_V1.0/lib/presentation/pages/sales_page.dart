import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/sale_item.dart';
import '../../data/models/stock_alert.dart';
import '../../logic/controllers/product_controller.dart';
import '../../logic/controllers/sale_controller.dart';
import '../../logic/controllers/stock_alert_controller.dart';
import '../../logic/observers/stock_observer.dart';
import '../../logic/observers/stock_change_notifier.dart';
import '../../logic/results/operation_result.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({
    required this.saleController,
    required this.productController,
    required this.stockAlertController,
    super.key,
  });

  final SaleController saleController;
  final ProductController productController;
  final StockAlertController stockAlertController;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin
    implements StockObserver {
  late TabController _tabController;
  List<StockAlert> _criticalAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    StockChangeNotifier.instance.attach(this);
    _loadCriticalAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    StockChangeNotifier.instance.detach(this);
    super.dispose();
  }

  @override
  void onStockChanged(Product product, int oldStock, int newStock) {
    if (mounted) {
      _loadCriticalAlerts();
    }
  }

  @override
  void onStockUnavailable(Product product) {
    if (mounted) {
      _loadCriticalAlerts();
    }
  }

  Future<void> _loadCriticalAlerts() async {
    final result = await widget.stockAlertController.getTriggeredAlerts();
    if (mounted && result.isSuccess) {
      setState(() {
        _criticalAlerts = result.data ?? [];
      });
    }
  }

  void _showTriggeredAlertsDialog() async {
    final productResult =
        await widget.productController.getProducts(includeInactive: true);
    if (!mounted || !productResult.isSuccess || productResult.data == null) {
      return;
    }

    final productsMap = {for (var p in productResult.data!) p.id: p};
    final criticalProducts = _criticalAlerts
        .map((alert) => productsMap[alert.productId])
        .whereType<Product>()
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.amber),
              SizedBox(width: 8),
              Text('Alertas de Stock Crítico'),
            ],
          ),
          content: criticalProducts.isEmpty
              ? const Text(
                  'No hay productos con existencias críticas actualmente.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: criticalProducts.map((product) {
                    final alert = _criticalAlerts
                        .firstWhere((a) => a.productId == product.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '⚠ ${product.name} - SKU: ${product.sku} (Stock: ${product.stock}, Mín: ${alert.minimumQuantity})',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationBell() {
    if (_criticalAlerts.isEmpty) {
      return const IconButton(
        icon: Icon(Icons.notifications_none),
        onPressed: null,
      );
    }

    return Badge(
      label: Text(_criticalAlerts.length.toString()),
      backgroundColor: Colors.red,
      child: IconButton(
        icon: const Icon(Icons.notifications_active, color: Colors.amber),
        onPressed: _showTriggeredAlertsDialog,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas de Venta'),
        actions: [
          _buildNotificationBell(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'Nueva Venta'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CreateSaleTab(
            saleController: widget.saleController,
            productController: widget.productController,
            stockAlertController: widget.stockAlertController,
          ),
          _SalesHistoryTab(
            saleController: widget.saleController,
            productController: widget.productController,
            stockAlertController: widget.stockAlertController,
          ),
        ],
      ),
    );
  }
}

class _CreateSaleTab extends StatefulWidget {
  const _CreateSaleTab({
    required this.saleController,
    required this.productController,
    required this.stockAlertController,
  });

  final SaleController saleController;
  final ProductController productController;
  final StockAlertController stockAlertController;

  @override
  State<_CreateSaleTab> createState() => _CreateSaleTabState();
}

class _CreateSaleTabState extends State<_CreateSaleTab> {
  final List<SaleItem> _saleItems = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _observationsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddProductButton(),
          const SizedBox(height: 20),
          if (_saleItems.isNotEmpty) ...[
            _buildSaleItemsList(),
            const SizedBox(height: 20),
            _buildTotalsSummary(),
            const SizedBox(height: 20),
          ],
          _buildPaymentMethodSelector(),
          const SizedBox(height: 16),
          _buildCustomerInfoFields(),
          const SizedBox(height: 16),
          _buildObservationsField(),
          const SizedBox(height: 24),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Producto'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSaleItemsList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _saleItems.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, index) {
          final item = _saleItems[index];

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.product.sku}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cantidad: ${item.quantity}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Unitario: \$${item.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF176B87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () => _removeItem(index),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalsSummary() {
    final subtotal = _saleItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final taxAmount = subtotal * 0.15;
    final total = subtotal + taxAmount;

    return Card(
      color: const Color(0xFF176B87).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA (15%):'),
                Text(
                  '\$${taxAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF176B87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pago',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<PaymentMethod>(
          value: _paymentMethod,
          isExpanded: true,
          items: PaymentMethod.values
              .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(_paymentMethodLabel(method)),
                  ))
              .toList(),
          onChanged: (method) {
            if (method != null) {
              setState(() => _paymentMethod = method);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomerInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Cliente (Opcional)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Cliente',
            hintText: 'Juan Pérez',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customerEmailController,
          decoration: const InputDecoration(
            labelText: 'Correo Electrónico',
            hintText: 'cliente@example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildObservationsField() {
    return TextField(
      controller: _observationsController,
      decoration: const InputDecoration(
        labelText: 'Observaciones (Opcional)',
        hintText: 'Ej: Cliente frecuente, entrega rápida...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saleItems.isEmpty || _isLoading ? null : _createSale,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle),
        label: Text(_isLoading ? 'Procesando...' : 'Confirmar Venta'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFF176B87),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showAddProductDialog() async {
    final productResult = await widget.productController.getProducts();

    if (!productResult.isSuccess || productResult.data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productResult.message)),
        );
      }

      return;
    }

    if (!mounted) return;

    final products = productResult.data!
        .where((product) => product.isActive && product.stock > 0)
        .toList();

    if (products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay productos disponibles para vender.'),
          ),
        );
      }

      return;
    }

    showDialog(
      context: context,
      builder: (_) => _AddProductDialog(
        products: products,
        onAddItem: _addSaleItem,
      ),
    );
  }

  void _addSaleItem(Product product, int quantity) {
    final itemId = 'ITEM-${DateTime.now().millisecondsSinceEpoch}';
    final saleItem = SaleItem(
      id: itemId,
      product: product,
      quantity: quantity,
      unitPrice: product.price,
    );

    setState(() {
      _saleItems.add(saleItem);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
  }

  Future<void> _checkPostSaleAlerts(List<SaleItem> soldItems) async {
    final List<String> criticalWarnings = [];

    for (final item in soldItems) {
      final productResult =
          await widget.productController.getProductById(item.product.id);
      if (productResult.isSuccess && productResult.data != null) {
        final product = productResult.data!;
        final alertResult =
            await widget.stockAlertController.getAlertByProductId(product.id);
        if (alertResult.isSuccess && alertResult.data != null) {
          final alert = alertResult.data!;
          if (alert.isActive && product.stock <= alert.minimumQuantity) {
            criticalWarnings.add(
              '• ${product.name} (SKU: ${product.sku}): '
              'Stock actual ${product.stock} (Mínimo: ${alert.minimumQuantity})',
            );
          }
        }
      }
    }

    if (criticalWarnings.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('¡Advertencia de Stock!'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Los siguientes productos han quedado por debajo o igual del límite mínimo configurado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...criticalWarnings.map((w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(w),
                      )),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _createSale() async {
    setState(() => _isLoading = true);

    final soldItemsCopy = List<SaleItem>.from(_saleItems);

    final result = await widget.saleController.createSale(
      items: soldItemsCopy,
      paymentMethod: _paymentMethod,
      customerName: _customerNameController.text,
      customerEmail: _customerEmailController.text,
      observations: _observationsController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
      await _checkPostSaleAlerts(soldItemsCopy);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _saleItems.clear();
      _paymentMethod = PaymentMethod.cash;
      _customerNameController.clear();
      _customerEmailController.clear();
      _observationsController.clear();
    });
  }

  String _paymentMethodLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'Efectivo',
      PaymentMethod.card => 'Tarjeta',
      PaymentMethod.transfer => 'Transferencia',
      PaymentMethod.other => 'Otro',
    };
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({
    required this.products,
    required this.onAddItem,
  });

  final List<Product> products;
  final Function(Product, int) onAddItem;

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<Product>(
            hint: const Text('Selecciona un producto'),
            isExpanded: true,
            value: _selectedProduct,
            items: widget.products
                .map((product) => DropdownMenuItem(
                      value: product,
                      child: Text(product.name),
                    ))
                .toList(),
            onChanged: (product) {
              setState(() => _selectedProduct = product);
            },
          ),
          const SizedBox(height: 16),
          if (_selectedProduct != null)
            Text(
              'Stock disponible: ${_selectedProduct!.stock}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedProduct == null ? null : _addItem,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _addItem() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida.')),
      );

      return;
    }

    if (quantity > _selectedProduct!.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No hay suficiente stock. Disponible: ${_selectedProduct!.stock}',
          ),
        ),
      );

      return;
    }

    widget.onAddItem(_selectedProduct!, quantity);
    Navigator.pop(context);
  }
}

class _SalesHistoryTab extends StatefulWidget {
  const _SalesHistoryTab({
    required this.saleController,
    required this.productController,
    required this.stockAlertController,
  });

  final SaleController saleController;
  final ProductController productController;
  final StockAlertController stockAlertController;

  @override
  State<_SalesHistoryTab> createState() => _SalesHistoryTabState();
}

class _SalesHistoryTabState extends State<_SalesHistoryTab> {
  final _searchController = TextEditingController();
  SaleStatus? _selectedStatus;
  late Future<OperationResult<List<Sale>>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSales() {
    _salesFuture = widget.saleController.searchSales(
      query: _searchController.text,
      status: _selectedStatus,
    );
  }

  void _showSaleDetailDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Envolvemos el texto en un Expanded para que no empuje el badge hacia afuera
              Expanded(
                child: Text(
                  'Detalle: ${sale.saleNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow
                      .ellipsis, // Evita desbordamiento con puntos suspensivos
                ),
              ),
              const SizedBox(
                  width: 8), // Un pequeño espacio de separación seguro
              _buildStatusBadge(sale.status),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${_formatDate(sale.createdAt)}',
                    style: const TextStyle(fontSize: 13)),
                Text('Pago: ${_paymentMethodLabel(sale.paymentMethod)}',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                if (sale.customerName.isNotEmpty) ...[
                  Text(
                    'Cliente: ${sale.customerName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (sale.customerEmail.isNotEmpty)
                    Text('Email: ${sale.customerEmail}',
                        style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                if (sale.observations.isNotEmpty) ...[
                  Text('Observaciones: ${sale.observations}',
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 13)),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                const Text('Productos Vendidos',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(2),
                    4: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
                      children: [
                        TableCell(
                            child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text('Producto',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)))),
                        TableCell(
                            child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text('SKU',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)))),
                        TableCell(
                            child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text('Cant',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)))),
                        TableCell(
                            child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text('Precio',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)))),
                        TableCell(
                            child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Text('Total',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)))),
                      ],
                    ),
                    ...sale.items.map((item) => TableRow(
                          children: [
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(item.product.name,
                                        style: const TextStyle(fontSize: 11)))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(item.product.sku,
                                        style: const TextStyle(fontSize: 11)))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(item.quantity.toString(),
                                        style: const TextStyle(fontSize: 11)))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                        '\$${item.unitPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11)))),
                            TableCell(
                                child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                        '\$${item.subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11)))),
                          ],
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: \$${sale.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12)),
                        Text(
                            'IVA (15%): \$${sale.taxAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          'Total: \$${sale.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF176B87)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (sale.isCompleted) ...[
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirmCancelSale(dialogContext, sale),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Venta'),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCancelSale(BuildContext dialogContext, Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar cancelación'),
          content: Text(
              '¿Realmente desea cancelar la venta ${sale.saleNumber}? Esta acción restablecerá el inventario de los productos correspondientes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final result = await widget.saleController.cancelSale(sale.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
        ),
      );

      if (result.isSuccess) {
        Navigator.pop(dialogContext); // cierra el detalle
        setState(() {
          _loadSales();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: FutureBuilder<OperationResult<List<Sale>>>(
            future: _salesFuture,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.isSuccess) {
                return Center(
                  child: Text(
                    snapshot.data?.message ?? 'Error desconocido',
                  ),
                );
              }

              final sales = snapshot.data!.data as List<Sale>;

              if (sales.isEmpty) {
                return const Center(
                  child: Text('No hay ventas registradas'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _buildSaleCard(sales[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSalesSearchField(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSalesStatusDropdown(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Actualizar',
                        onPressed: () {
                          setState(() => _loadSales());
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: _buildSalesSearchField(),
                ),
                SizedBox(
                  width: 180,
                  child: _buildSalesStatusDropdown(),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: () {
                    setState(() => _loadSales());
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSalesSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() => _loadSales());
      },
      decoration: InputDecoration(
        labelText: 'Buscar por venta o cliente',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _loadSales());
                },
                icon: const Icon(Icons.clear),
              ),
      ),
    );
  }

  Widget _buildSalesStatusDropdown() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SaleStatus?>(
          value: _selectedStatus,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: null, child: Text('Todos')),
            DropdownMenuItem(
                value: SaleStatus.completed, child: Text('Completada')),
            DropdownMenuItem(
                value: SaleStatus.cancelled, child: Text('Cancelada')),
            DropdownMenuItem(
                value: SaleStatus.pending, child: Text('Pendiente')),
          ],
          onChanged: (val) {
            setState(() {
              _selectedStatus = val;
              _loadSales();
            });
          },
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      child: InkWell(
        onTap: () => _showSaleDetailDialog(sale),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sale.saleNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF176B87),
                    ),
                  ),
                  _buildStatusBadge(sale.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${_formatDate(sale.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sale.items.length} producto(s)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Total: \$${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (sale.customerName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Cliente: ${sale.customerName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pago: ${_paymentMethodLabel(sale.paymentMethod)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Text(
                    'Ver detalles →',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF176B87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SaleStatus status) {
    final color = switch (status) {
      SaleStatus.pending => Colors.orange,
      SaleStatus.completed => Colors.green,
      SaleStatus.cancelled => Colors.red,
    };

    final label = switch (status) {
      SaleStatus.pending => 'Pendiente',
      SaleStatus.completed => 'Completada',
      SaleStatus.cancelled => 'Cancelada',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _paymentMethodLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'Efectivo',
      PaymentMethod.card => 'Tarjeta',
      PaymentMethod.transfer => 'Transferencia',
      PaymentMethod.other => 'Otro',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
