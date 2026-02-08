import 'dart:typed_data';

import 'package:excel/excel.dart';
import '../models/admin_product.dart';

/// Result of parsing an XLSX file.
class XlsxParseResult {
  final List<AdminProduct> products;
  final List<String> errors;

  XlsxParseResult({required this.products, required this.errors});
}

/// Strict expected header in this exact order
const List<String> _expectedHeader = [
  'name',
  'category',
  'base_price',
  'base_unit',
  'stock',
  'image_url',
  'is_out_of_stock',
];

/// Parse XLSX bytes into AdminProduct list. Throws FormatException on invalid format.
XlsxParseResult parseXlsxBytes(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) {
    throw FormatException('The XLSX file contains no sheets');
  }

  final sheet = excel.tables[excel.tables.keys.first]!;
  if (sheet.maxRows == 0) {
    return XlsxParseResult(products: [], errors: ['Sheet is empty']);
  }

  // Read header row (first row)
  final headerRow = sheet.rows.first;
  final header = headerRow.map((cell) => (cell?.value ?? '').toString().trim().toLowerCase()).toList();

  // Validate header exact match
  if (header.length < _expectedHeader.length) {
    throw FormatException('Invalid XLSX header: expected columns ${_expectedHeader.join(', ')}');
  }
  for (var i = 0; i < _expectedHeader.length; i++) {
    if (header[i] != _expectedHeader[i]) {
      throw FormatException('Invalid header column at position ${i + 1}: expected "${_expectedHeader[i]}" but found "${header[i]}"');
    }
  }

  final products = <AdminProduct>[];
  final errors = <String>[];

  // Parse each subsequent row
  for (var r = 1; r < sheet.maxRows; r++) {
    final row = sheet.rows[r];
    if (row.every((cell) => cell == null || (cell.value ?? '').toString().trim().isEmpty)) {
      // skip empty rows
      continue;
    }

    try {
      String cellAt(int idx) => (idx < row.length && row[idx] != null) ? '${row[idx]!.value}'.trim() : '';

      final name = cellAt(0);
      final category = cellAt(1);
      final basePriceRaw = cellAt(2);
      final baseUnit = cellAt(3);
      final stockRaw = cellAt(4);
      final imageUrl = cellAt(5).isEmpty ? null : cellAt(5);
      final isOutOfStockRaw = cellAt(6).toLowerCase();

      if (name.isEmpty) throw FormatException('Row ${r + 1}: "name" is required');
      if (category.isEmpty) throw FormatException('Row ${r + 1}: "category" is required');

      final basePrice = int.tryParse(basePriceRaw) ?? (basePriceRaw.isEmpty ? 0 : -999999);
      if (basePrice == -999999) throw FormatException('Row ${r + 1}: "base_price" is invalid');

      final stock = int.tryParse(stockRaw) ?? (stockRaw.isEmpty ? 0 : -999999);
      if (stock == -999999) throw FormatException('Row ${r + 1}: "stock" is invalid');

      bool isOutOfStock;
      if (isOutOfStockRaw == 'true' || isOutOfStockRaw == '1') {
        isOutOfStock = true;
      } else if (isOutOfStockRaw == 'false' || isOutOfStockRaw == '0' || isOutOfStockRaw == '') {
        isOutOfStock = false;
      } else {
        throw FormatException('Row ${r + 1}: "is_out_of_stock" must be true/false');
      }

      products.add(AdminProduct(
        name: name,
        category: category,
        basePrice: basePrice,
        baseUnit: baseUnit,
        stock: stock,
        imageUrl: imageUrl,
        isOutOfStock: isOutOfStock,
      ));
    } catch (e) {
      errors.add(e.toString());
    }
  }

  return XlsxParseResult(products: products, errors: errors);
}
