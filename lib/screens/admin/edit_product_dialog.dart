import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/admin_product.dart';
import '../services/admin_service.dart';

class EditProductDialog extends StatefulWidget {
  final AdminProduct product;
  final VoidCallback onProductUpdated;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _adminService = AdminService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late String _selectedUnit;

  bool _loading = false;

  final _units = ['kg', 'g', 'L', 'ml', 'piece', 'pack', 'pcs'];

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.product.name);

    _priceController = TextEditingController(
      text: widget.product.basePrice.toString(),
    );

    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );

    _selectedUnit = widget.product.baseUnit;
  }

  Future<void> _updateProduct() async {
    setState(() => _loading = true);

    try {
      if (!RegExp(r'^\d+$').hasMatch(_priceController.text) ||
          !RegExp(r'^\d+$').hasMatch(_stockController.text)) {
        throw Exception('Only whole numbers allowed');
      }

      final price = int.parse(_priceController.text);
      final stock = int.parse(_stockController.text);

      await _adminService.updateProduct(
        productId: widget.product.id, // ✅ UUID, NOT STRING
        name: _nameController.text.trim(),
        basePrice: price,
        baseUnit: _selectedUnit,
      );

      await _adminService.updateProductStock(
        productId: widget.product.id,
        newStock: stock,
      );

      widget.onProductUpdated();
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _nameController),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          DropdownButtonFormField(
            value: _selectedUnit,
            items: _units
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (v) => setState(() => _selectedUnit = v!),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _updateProduct,
            child: const Text('Update'),
          ),
        ]),
      ),
    );
  }
}
