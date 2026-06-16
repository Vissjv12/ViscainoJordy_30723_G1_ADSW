import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../logic/controllers/auth_controller.dart';
import '../../logic/controllers/product_controller.dart';
import '../../logic/services/product_service.dart';
import '../widgets/product_card.dart';
import 'product_form_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    required this.authController,
    required this.productController,
    super.key,
  });

  final AuthController authController;
  final ProductController productController;

  @override
  State<InventoryPage> createState() =>
      _InventoryPageState();
}

class _InventoryPageState
    extends State<InventoryPage> {
  final _searchController = TextEditingController();

  List<Product> _products = [];
  List<String> _categories = [];

  String _selectedCategory = '';
  String _selectedStatus = 'active';

  ProductSortOption _sortOption =
      ProductSortOption.name;

  bool _ascending = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reloadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final allResult =
        await widget.productController.getProducts(
      includeInactive: true,
    );

    final categories = <String>{};

    for (final product
        in allResult.data ?? <Product>[]) {
      categories.add(product.category);
    }

    final searchResult =
        await widget.productController.searchProducts(
      query: _searchController.text,
      category: _selectedCategory.isEmpty
          ? null
          : _selectedCategory,
      status: _statusFilter,
      sortOption: _sortOption,
      ascending: _ascending,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = categories.toList()..sort();
      _products =
          searchResult.data ?? <Product>[];
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
          productController:
              widget.productController,
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

    final result =
        await widget.productController
            .deactivateProduct(product.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );

    if (result.isSuccess) {
      await _reloadInventory();
    }
  }

  void _logout() {
    final result = widget.authController.logout();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        widget.authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario PaperBoost'),
        actions: [
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Center(
              child: Text(
                currentUser?.email ?? '',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildProductList(),
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
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment:
              WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  _reloadInventory();
                },
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o SKU',
                  prefixIcon:
                      const Icon(Icons.search),
                  border:
                      const OutlineInputBorder(),
                  suffixIcon:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _reloadInventory();
                              },
                              icon:
                                  const Icon(Icons.clear),
                            ),
                ),
              ),
            ),
            _dropdownContainer(
              label: 'Categoría',
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas'),
                  ),
                  ..._categories.map(
                    (category) =>
                        DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory =
                        value ?? '';
                  });
                  _reloadInventory();
                },
              ),
            ),
            _dropdownContainer(
              label: 'Estado',
              child: DropdownButton<String>(
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
                    _selectedStatus =
                        value ?? 'active';
                  });
                  _reloadInventory();
                },
              ),
            ),
            _dropdownContainer(
              label: 'Ordenar por',
              child:
                  DropdownButton<ProductSortOption>(
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
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _sortOption = value;
                  });

                  _reloadInventory();
                },
              ),
            ),
            IconButton.filledTonal(
              tooltip: _ascending
                  ? 'Orden ascendente'
                  : 'Orden descendente',
              onPressed: () {
                setState(() {
                  _ascending = !_ascending;
                });

                _reloadInventory();
              },
              icon: Icon(
                _ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _reloadInventory,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownContainer({
    required String label,
    required Widget child,
  }) {
    return SizedBox(
      width: 180,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_products.isEmpty) {
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
        final columns =
            constraints.maxWidth >= 1100
                ? 3
                : constraints.maxWidth >= 700
                    ? 2
                    : 1;

        if (columns == 1) {
          return ListView.builder(
            padding:
                const EdgeInsets.only(bottom: 90),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];

              return ProductCard(
                product: product,
                onEdit: () => _openProductForm(
                  product: product,
                ),
                onDeactivate: () =>
                    _confirmDeactivate(product),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 90),
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];

            return ProductCard(
              product: product,
              onEdit: () => _openProductForm(
                product: product,
              ),
              onDeactivate: () =>
                  _confirmDeactivate(product),
            );
          },
        );
      },
    );
  }
}