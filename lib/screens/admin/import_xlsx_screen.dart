import 'dart:typed_data';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../models/admin_product.dart';
import '../../services/admin_product_service.dart';
import '../../utils/xlsx_parser.dart';

/// Screen that allows admin to pick XLSX file, preview and import.
class ImportXlsxScreen extends StatefulWidget {
  const ImportXlsxScreen({Key? key}) : super(key: key);

  @override
  _ImportXlsxScreenState createState() => _ImportXlsxScreenState();
}

class _ImportXlsxScreenState extends State<ImportXlsxScreen> {
  final AdminProductService _service = AdminProductService();
  List<AdminProduct> _preview = [];
  List<String> _errors = [];
  bool _parsing = false;
  bool _importing = false;
  double _progress = 0;

  Future<void> _pickFile() async {
    setState(() {
      _parsing = true;
      _preview = [];
      _errors = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result == null) return;

      Uint8List bytes;
      final picked = result.files.first;
      if (picked.bytes != null) {
        bytes = picked.bytes!;
      } else if (!kIsWeb && picked.path != null) {
        bytes = await File(picked.path!).readAsBytes();
      } else {
        throw Exception('Unable to read picked file bytes (platform may be web without bytes)');
      }

      final parseResult = parseXlsxBytes(bytes);
      setState(() {
        _preview = parseResult.products;
        _errors = parseResult.errors;
      });
    } catch (e) {
      setState(() {
        _errors = [e.toString()];
      });
    } finally {
      setState(() {
        _parsing = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_preview.isEmpty) return;
    setState(() {
      _importing = true;
      _progress = 0;
    });

    final total = _preview.length;
    final importErrors = <String>[];
    for (var i = 0; i < total; i++) {
      final p = _preview[i];
      try {
        await _service.upsertProduct(p);
      } catch (e) {
        importErrors.add('Row ${i + 1}: $e');
      }
      setState(() {
        _progress = (i + 1) / total;
      });
    }

    setState(() {
      _importing = false;
      _progress = 0;
    });

    if (importErrors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import completed successfully')));
      Navigator.of(context).pop();
    } else {
      // Show errors
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Errors during import'),
          content: SingleChildScrollView(child: Text(importErrors.join('\n'))),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Import Products - XLSX')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _parsing || _importing ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Pick XLSX file'),
            ),
            const SizedBox(height: 12),
            if (_parsing) const LinearProgressIndicator(),
            if (_errors.isNotEmpty) ...[
              Text('Parsing errors:', style: theme.textTheme.titleMedium?.copyWith(color: Colors.red)),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  itemCount: _errors.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: Text(_errors[i]),
                  ),
                ),
              ),
            ] else if (_preview.isEmpty) ...[
              const SizedBox(height: 8),
              const Text('No preview available. Pick a valid .xlsx file matching the required format.'),
              const SizedBox(height: 8),
              const Text('Required columns (in order): name, category, base_price, base_unit, stock, image_url, is_out_of_stock'),
            ] else ...[
              Text('Preview (${_preview.length} products):', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _preview.length,
                  itemBuilder: (_, i) {
                    final p = _preview[i];
                    return ListTile(
                      leading: p.imageUrl != null && p.imageUrl!.isNotEmpty ? Image.network(p.imageUrl!, width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.image),
                      title: Text(p.name),
                      subtitle: Text('${p.category} • ${p.basePrice.toStringAsFixed(2)}/${p.baseUnit} • stock: ${p.stock}'),
                      trailing: p.isOutOfStock ? const Chip(label: Text('OUT')) : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (_importing)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text('Importing ${(_progress * _preview.length).toStringAsFixed(0)} / ${_preview.length}'),
                  ],
                )
              else
                Row(
                  children: [
                    ElevatedButton.icon(onPressed: _confirmImport, icon: const Icon(Icons.check), label: const Text('Confirm Import')),
                    const SizedBox(width: 12),
                    TextButton(onPressed: () => setState(() => _preview = []), child: const Text('Clear')),
                  ],
                )
            ]
          ],
        ),
      ),
    );
  }
}
