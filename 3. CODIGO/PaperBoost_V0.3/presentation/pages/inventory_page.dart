import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../data/models/stock_alert.dart';
import '../../logic/controllers/auth_controller.dart';
import '../../logic/controllers/product_controller.dart';
import '../../logic/controllers/stock_alert_controller.dart';
import '../../logic/observers/stock_observer.dart';
import '../../logic/observers/stock_change_notifier.dart';
import '../../logic/results/operation_result.dart';
import '../../logic/services/product_service.dart';
import '../widgets/product_card.dart';
import 'product_form_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    required this.authController,
    required this.productController,
    required this.stockAlertController,
    this.onLogout,
    this.onNavigateToSales,
    super.key,
  });

  final AuthController authController;
  final ProductController productController;
  final StockAlertController stockAlertController;
  final VoidCallback? onLogout;
  final VoidCallback? onNavigateToSales;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin
    implements StockObserver {
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Product> _products = [];
  List<String> _categories = [];
  Map<String, StockAlert> _alerts = {};

  String _selectedCategory = '';
  String _selectedStatus = 'active';

  ProductSortOption _sortOption = ProductSortOption.name;

  bool _ascending = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    StockChangeNotifier.instance.attach(this);
    _reloadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    StockChangeNotifier.instance.detach(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onStockChanged(Product product, int oldStock, int newStock) {
    if (mounted) {
      _reloadInventory();
    }
  }

  @override
  void onStockUnavailable(Product product) {
    if (mounted) {
      _reloadInventory();
    }
  }

  ProductStatus? get _statusFilter {
    switch (_selectedStatus) {
      case 'active':
        return ProductStatus.active;
      case 'inactive':
        return ProductStatus.inactive;
      default:
        return null;
    }
  }

  Future<void> _reloadInventory() async {
    setState(() {
      _isLoading = true;
    });

    final allResult = await widget.productController.getProducts(
      includeInactive: true,
    );

    final categories = <String>{};

    for (final product in allResult.data ?? <Product>[]) {
      categories.add(product.category);
    }

    final searchResult = await widget.productController.searchProducts(
      query: _searchController.text,
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
      status: _statusFilter,
      sortOption: _sortOption,
      ascending: _ascending,
    );

    final alertsResult = await widget.stockAlertController.getAlerts();
    final Map<String, StockAlert> loadedAlerts = {};
    for (final alert in alertsResult.data ?? <StockAlert>[]) {
      loadedAlerts[alert.productId] = alert;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = categories.toList()..sort();
      _products = searchResult.data ?? <Product>[];
      _alerts = loadedAlerts;
      _isLoading = false;
    });
  }

  Future<void> _openProductForm({
    Product? product,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          productController: widget.productController,
          product: product,
        ),
      ),
    );

    if (changed == true) {
      await _reloadInventory();
    }
  }

  Future<void> _confirmDeactivate(
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar baja'),
          content: Text(
            '¿Desea dar de baja el producto '
            '"${product.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await widget.productController.deactivateProduct(product.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.isSuccess ? null : Theme.of(context).colorScheme.error,
      ),
    );

    if (result.isSuccess) {
      await _reloadInventory();
    }
  }

  void _openConfigureAlert(Product product) async {
    final alert = _alerts[product.id];
    final isNew = alert == null;

    final quantityController = TextEditingController(
      text: alert?.minimumQuantity.toString() ?? '5',
    );
    bool isActive = alert?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Configurar Alerta - ${product.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Define la cantidad mínima para notificar cuando las existencias alcancen o bajen de este límite.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad Mínima',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alerta Activa'),
                      subtitle:
                          const Text('Habilita/deshabilita notificaciones'),
                      value: isActive,
                      onChanged: (val) {
                        setStateDialog(() {
                          isActive = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final minQty = int.tryParse(quantityController.text) ?? -1;
    if (minQty < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Cantidad mínima inválida. Debe ser mayor o igual a 0.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    OperationResult<StockAlert> opResult;
    if (isNew) {
      opResult = await widget.stockAlertController.createAlert(
        productId: product.id,
        minimumQuantity: minQty,
      );
    } else {
      opResult = await widget.stockAlertController.updateAlert(
        id: alert.id,
        minimumQuantity: minQty,
        isActive: isActive,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(opResult.message),
          backgroundColor: opResult.isSuccess ? Colors.green : Colors.red,
        ),
      );
      if (opResult.isSuccess) {
        _reloadInventory();
      }
    }
  }

  void _showTriggeredAlertsDialog() {
    final criticalProducts = _products.where((product) {
      final alert = _alerts[product.id];
      return product.isActive &&
          alert != null &&
          alert.isActive &&
          product.stock <= alert.minimumQuantity;
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alertas de Stock Crítico',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: criticalProducts.isEmpty
              ? const Text(
                  'No hay productos con existencias críticas actualmente.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: criticalProducts.length,
                    itemBuilder: (context, index) {
                      final product = criticalProducts[index];
                      final alert = _alerts[product.id]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '⚠ ${product.name} - SKU: ${product.sku} (Stock: ${product.stock}, Mín: ${alert.minimumQuantity})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
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
    final criticalCount = _products.where((product) {
      final alert = _alerts[product.id];
      return product.isActive &&
          alert != null &&
          alert.isActive &&
          product.stock <= alert.minimumQuantity;
    }).length;

    if (criticalCount == 0) {
      return const IconButton(
        icon: Icon(Icons.notifications_none),
        onPressed: null,
      );
    }

    return Badge(
      label: Text(criticalCount.toString()),
      backgroundColor: Colors.red,
      child: IconButton(
        icon: const Icon(Icons.notifications_active, color: Colors.amber),
        onPressed: _showTriggeredAlertsDialog,
      ),
    );
  }

  void _logout() {
    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario PaperBoost'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Todos'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Crítico'),
          ],
        ),
        actions: [
          _buildNotificationBell(),
          if (isMobile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'logout') _logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Cerrar sesión')),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            IconButton(
              tooltip: 'Nueva venta',
              onPressed: widget.onNavigateToSales,
              icon: const Icon(Icons.receipt_long),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _openProductForm(),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Registrar producto'),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              children: [
                if (!isMobile) ...[
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                ],
                _buildFilters(),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildProductList(showOnlyCritical: false),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildProductList(showOnlyCritical: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: widget.onNavigateToSales,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Nueva venta'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openProductForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar producto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return _buildMobileFilters();
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: _buildSearchField(),
                ),
                _dropdownContainer(
                  label: 'Categoría',
                  child: _buildCategoryDropdown(),
                ),
                _dropdownContainer(
                  label: 'Estado',
                  child: _buildStatusDropdown(),
                ),
                _dropdownContainer(
                  label: 'Ordenar por',
                  child: _buildSortDropdown(),
                ),
                IconButton.filledTonal(
                  tooltip:
                      _ascending ? 'Orden ascendente' : 'Orden descendente',
                  onPressed: () {
                    setState(() {
                      _ascending = !_ascending;
                    });
                    _reloadInventory();
                  },
                  icon: Icon(
                    _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _reloadInventory,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dropdownContainer(
                label: 'Categoría',
                child: _buildCategoryDropdown(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownContainer(
                label: 'Estado',
                child: _buildStatusDropdown(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dropdownContainer(
                label: 'Ordenar por',
                child: _buildSortDropdown(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: _ascending ? 'Orden ascendente' : 'Orden descendente',
              onPressed: () {
                setState(() {
                  _ascending = !_ascending;
                });
                _reloadInventory();
              },
              icon: Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _reloadInventory,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        _reloadInventory();
      },
      decoration: InputDecoration(
        labelText: 'Buscar por nombre o SKU',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _reloadInventory();
                },
                icon: const Icon(Icons.clear),
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _selectedCategory,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Todas'),
        ),
        ..._categories.map(
          (category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value ?? '';
        });
        _reloadInventory();
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButton<String>(
      value: _selectedStatus,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: 'active',
          child: Text('Activos'),
        ),
        DropdownMenuItem(
          value: 'inactive',
          child: Text('Inactivos'),
        ),
        DropdownMenuItem(
          value: 'all',
          child: Text('Todos'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value ?? 'active';
        });
        _reloadInventory();
      },
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<ProductSortOption>(
      value: _sortOption,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: ProductSortOption.name,
          child: Text('Nombre'),
        ),
        DropdownMenuItem(
          value: ProductSortOption.price,
          child: Text('Precio'),
        ),
        DropdownMenuItem(
          value: ProductSortOption.stock,
          child: Text('Stock'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _sortOption = value;
        });
        _reloadInventory();
      },
    );
  }

  Widget _dropdownContainer({
    required String label,
    required Widget child,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      child: child,
    );
  }

  Widget _buildProductList({required bool showOnlyCritical}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final displayProducts = showOnlyCritical
        ? _products.where((product) {
            final alert = _alerts[product.id];
            return product.isActive &&
                alert != null &&
                alert.isActive &&
                product.stock <= alert.minimumQuantity;
          }).toList()
        : _products;

    if (displayProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
            ),
            SizedBox(height: 12),
            Text(
              'No se encontraron productos.',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;

        if (columns == 1) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: displayProducts.length,
            itemBuilder: (context, index) {
              final product = displayProducts[index];

              return ProductCard(
                product: product,
                stockAlert: _alerts[product.id],
                onConfigureAlert: () => _openConfigureAlert(product),
                onEdit: () => _openProductForm(
                  product: product,
                ),
                onDeactivate: () => _confirmDeactivate(product),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            final product = displayProducts[index];

            return ProductCard(
              product: product,
              stockAlert: _alerts[product.id],
              onConfigureAlert: () => _openConfigureAlert(product),
              onEdit: () => _openProductForm(
                product: product,
              ),
              onDeactivate: () => _confirmDeactivate(product),
            );
          },
        );
      },
    );
  }
}
