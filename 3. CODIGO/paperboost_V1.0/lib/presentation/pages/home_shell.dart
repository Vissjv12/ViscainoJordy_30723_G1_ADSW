import 'package:flutter/material.dart';

import '../../logic/controllers/auth_controller.dart';
import '../../logic/controllers/product_controller.dart';
import '../../logic/controllers/sale_controller.dart';
import '../../logic/controllers/stock_alert_controller.dart';
import 'inventory_page.dart';
import 'sales_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.authController,
    required this.productController,
    required this.saleController,
    required this.stockAlertController,
    super.key,
  });

  final AuthController authController;
  final ProductController productController;
  final SaleController saleController;
  final StockAlertController stockAlertController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _logout() {
    final result = widget.authController.logout();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  void _navigateToSales() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InventoryPage(
            authController: widget.authController,
            productController: widget.productController,
            stockAlertController: widget.stockAlertController,
            onLogout: _logout,
            onNavigateToSales: _navigateToSales,
          ),
          SalesPage(
            saleController: widget.saleController,
            productController: widget.productController,
            stockAlertController: widget.stockAlertController,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ventas',
          ),
        ],
      ),
    );
  }
}
