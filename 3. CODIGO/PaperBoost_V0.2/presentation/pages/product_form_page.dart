import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../logic/controllers/product_controller.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    required this.productController,
    this.product,
    super.key,
  });

  final ProductController productController;
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() =>
      _ProductFormPageState();
}

class _ProductFormPageState
    extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _locationController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _skuController = TextEditingController(
      text: product?.sku ?? '',
    );

    _nameController = TextEditingController(
      text: product?.name ?? '',
    );

    _priceController = TextEditingController(
      text: product?.price.toStringAsFixed(2) ?? '',
    );

    _stockController = TextEditingController(
      text: product?.stock.toString() ?? '',
    );

    _categoryController = TextEditingController(
      text: product?.category ?? '',
    );

    _locationController = TextEditingController(
      text: product?.location ?? '',
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(
      _priceController.text
          .trim()
          .replaceAll(',', '.'),
    );

    final stock = int.tryParse(
      _stockController.text.trim(),
    );

    if (price == null || stock == null) {
      _showMessage(
        'Revise el precio y el stock ingresados.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (widget.isEditing) {
      await _updateProduct(
        price: price,
        stock: stock,
      );
    } else {
      await _registerProduct(
        price: price,
        stock: stock,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _registerProduct({
    required double price,
    required int stock,
  }) async {
    final result =
        await widget.productController.registerProduct(
      sku: _skuController.text,
      name: _nameController.text,
      price: price,
      stock: stock,
      category: _categoryController.text,
      location: _locationController.text,
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      _showMessage(
        result.message,
        isError: true,
      );
      return;
    }

    _showMessage(result.message);

    Navigator.pop(context, true);
  }

  Future<void> _updateProduct({
    required double price,
    required int stock,
  }) async {
    final currentProduct = widget.product;

    if (currentProduct == null) {
      return;
    }

    final updatedProduct = currentProduct.copyWith(
      sku: _skuController.text,
      name: _nameController.text,
      price: price,
      stock: stock,
      category: _categoryController.text,
      location: _locationController.text,
    );

    final result =
        await widget.productController.updateProduct(
      product: updatedProduct,
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      _showMessage(
        result.message,
        isError: true,
      );
      return;
    }

    _showMessage(result.message);

    Navigator.pop(context, true);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Editar producto'
        : 'Registrar producto';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 700,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode:
                      AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _skuController,
                        textCapitalization:
                            TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          prefixIcon:
                              Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'El SKU',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon:
                              Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'El nombre',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          prefixIcon:
                              Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final price = double.tryParse(
                            (value ?? '')
                                .replaceAll(',', '.'),
                          );

                          if (price == null ||
                              price <= 0) {
                            return 'Ingrese un precio mayor que cero.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockController,
                        keyboardType:
                            TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          prefixIcon:
                              Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final stock =
                              int.tryParse(value ?? '');

                          if (stock == null ||
                              stock < 0) {
                            return 'Ingrese un stock válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon:
                              Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'La categoría',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación',
                          prefixIcon:
                              Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _requiredValidator(
                          value,
                          'La ubicación',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                        false,
                                      );
                                    },
                              child:
                                  const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : _saveProduct,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSaving
                                    ? 'Guardando...'
                                    : 'Guardar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}