import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

/// Service to import/export customers in CSV format
class CustomerImportExportService {
  static final _supabase = Supabase.instance.client;

  /// Export customers to CSV file (downloads in browser)
  static Future<void> exportToCSV({
    required String companyId,
    String? status, // 'active', 'inactive', or null for all
  }) async {
    try {
      // Fetch customers
      var query = _supabase
          .from('customers')
          .select()
          .eq('company_id', companyId);
      
      if (status != null) {
        query = query.eq('status', status);
      }
      
      final data = await query.order('code', ascending: true);
      if (data.isEmpty) {
        throw Exception('Không có khách hàng nào để xuất');
      }

      // Build CSV content
      final headers = [
        'Mã KH',
        'Tên',
        'SĐT',
        'SĐT 2',
        'Email',
        'Số nhà',
        'Đường',
        'Phường/Xã',
        'Quận/Huyện',
        'Thành phố',
        'Địa chỉ đầy đủ',
        'Loại',
        'Kênh',
        'Hạng',
        'Hạn mức',
        'Công nợ',
        'Trạng thái',
        'Ngày tạo',
      ];

      final rows = <List<String>>[];
      rows.add(headers);

      for (final customer in data) {
        rows.add([
          customer['code'] ?? '',
          customer['name'] ?? '',
          customer['phone'] ?? '',
          customer['phone2'] ?? '',
          customer['email'] ?? '',
          customer['street_number'] ?? '',
          customer['street'] ?? '',
          customer['ward'] ?? '',
          customer['district'] ?? '',
          customer['city'] ?? '',
          customer['address'] ?? '',
          _translateType(customer['type']),
          customer['channel'] ?? '',
          _translateTier(customer['tier']),
          (customer['credit_limit'] ?? 0).toString(),
          (customer['total_debt'] ?? 0).toString(),
          customer['status'] == 'active' ? 'Hoạt động' : 'Ngưng',
          _formatDate(customer['created_at']),
        ]);
      }

      // Convert to CSV string
      final csvContent = rows.map((row) => row.map(_escapeCsvField).join(',')).join('\n');
      
      // Add BOM for Excel UTF-8 compatibility
      final csvWithBom = '\uFEFF$csvContent';
      
      // Create blob and download
      final bytes = utf8.encode(csvWithBom);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final fileName = 'khach_hang_${DateTime.now().toIso8601String().split('T')[0]}.csv';
      
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      AppLogger.api('Exported ${data.length} customers to $fileName');
    } catch (e) {
      AppLogger.error('Export error', e);
      rethrow;
    }
  }

  /// Import customers from CSV file
  static Future<ImportResult> importFromCSV({
    required String companyId,
    required String csvContent,
  }) async {
    try {
      final lines = const LineSplitter().convert(csvContent);
      if (lines.length < 2) {
        throw Exception('File CSV trống hoặc không có dữ liệu');
      }

      // Parse header to find column indices
      final headerLine = lines[0].replaceAll('\uFEFF', ''); // Remove BOM
      final headers = _parseCsvLine(headerLine);
      
      final colMap = <String, int>{};
      for (var i = 0; i < headers.length; i++) {
        final h = headers[i].toLowerCase().trim();
        if (h.contains('mã') || h == 'code') {
          colMap['code'] = i;
        } else if (h.contains('tên') || h == 'name') {
          colMap['name'] = i;
        } else if (h.contains('sđt') && !h.contains('2') || h == 'phone') {
          colMap['phone'] = i;
        } else if (h.contains('sđt 2') || h == 'phone2') {
          colMap['phone2'] = i;
        } else if (h.contains('email')) {
          colMap['email'] = i;
        } else if (h.contains('số nhà') || h == 'street_number') {
          colMap['street_number'] = i;
        } else if (h.contains('đường') || h == 'street') {
          colMap['street'] = i;
        } else if (h.contains('phường') || h == 'ward') {
          colMap['ward'] = i;
        } else if (h.contains('quận') || h == 'district') {
          colMap['district'] = i;
        } else if (h.contains('thành phố') || h == 'city') {
          colMap['city'] = i;
        } else if (h.contains('loại') || h == 'type') {
          colMap['type'] = i;
        } else if (h.contains('kênh') || h == 'channel') {
          colMap['channel'] = i;
        } else if (h.contains('hạng') || h == 'tier') {
          colMap['tier'] = i;
        }
      }

      if (!colMap.containsKey('name')) {
        throw Exception('Không tìm thấy cột "Tên" hoặc "name" trong file');
      }

      int added = 0;
      int updated = 0;
      int skipped = 0;
      final errors = <String>[];

      // Get existing codes for duplicate check
      final existingData = await _supabase
          .from('customers')
          .select('code')
          .eq('company_id', companyId);
      final existingCodes = (existingData as List)
          .map((e) => (e['code'] as String?)?.toUpperCase())
          .where((c) => c != null)
          .toSet();

      // Get next code number
      int nextCodeNum = 1;
      final lastCodeData = await _supabase
          .from('customers')
          .select('code')
          .eq('company_id', companyId)
          .ilike('code', 'KH-%')
          .order('code', ascending: false)
          .limit(1);
      if (lastCodeData.isNotEmpty) {
        final lastCode = lastCodeData[0]['code'] as String?;
        if (lastCode != null && lastCode.startsWith('KH-')) {
          nextCodeNum = (int.tryParse(lastCode.substring(3)) ?? 0) + 1;
        }
      }

      // Process each row
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final fields = _parseCsvLine(line);
          
          String getValue(String key) {
            final idx = colMap[key];
            if (idx == null || idx >= fields.length) return '';
            return fields[idx].trim();
          }

          final name = getValue('name');
          if (name.isEmpty) {
            skipped++;
            continue;
          }

          var code = getValue('code').toUpperCase();
          bool isNew = false;
          
          if (code.isEmpty) {
            // Generate new code
            code = 'KH-${nextCodeNum.toString().padLeft(4, '0')}';
            nextCodeNum++;
            isNew = true;
          } else if (!existingCodes.contains(code)) {
            isNew = true;
          }

          final customerData = {
            'company_id': companyId,
            'code': code,
            'name': name,
            'phone': getValue('phone').isNotEmpty ? getValue('phone') : null,
            'phone2': getValue('phone2').isNotEmpty ? getValue('phone2') : null,
            'email': getValue('email').isNotEmpty ? getValue('email') : null,
            'street_number': getValue('street_number').isNotEmpty ? getValue('street_number') : null,
            'street': getValue('street').isNotEmpty ? getValue('street') : null,
            'ward': getValue('ward').isNotEmpty ? getValue('ward') : null,
            'district': getValue('district').isNotEmpty ? getValue('district') : null,
            'city': getValue('city').isNotEmpty ? getValue('city') : 'Hồ Chí Minh',
            'type': _parseType(getValue('type')),
            'channel': getValue('channel').isNotEmpty ? getValue('channel') : null,
            'tier': _parseTier(getValue('tier')),
            'status': 'active',
          };

          if (isNew) {
            await _supabase.from('customers').insert(customerData);
            existingCodes.add(code);
            added++;
          } else {
            await _supabase
                .from('customers')
                .update(customerData)
                .eq('company_id', companyId)
                .eq('code', code);
            updated++;
          }
        } catch (e) {
          errors.add('Dòng $i: $e');
          skipped++;
        }
      }

      return ImportResult(
        added: added,
        updated: updated,
        skipped: skipped,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error('Import error', e);
      rethrow;
    }
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    
    return result;
  }

  static String _translateType(String? type) {
    switch (type) {
      case 'retail': return 'Khách lẻ';
      case 'wholesale': return 'Khách sỉ';
      case 'distributor': return 'NPP';
      case 'horeca': return 'Horeca';
      case 'other': return 'Khác';
      default: return type ?? '';
    }
  }

  static String _translateTier(String? tier) {
    switch (tier) {
      case 'diamond': return 'Kim cương';
      case 'gold': return 'Vàng';
      case 'silver': return 'Bạc';
      case 'bronze': return 'Đồng';
      default: return tier ?? 'Đồng';
    }
  }

  static String _parseType(String value) {
    final v = value.toLowerCase();
    if (v.contains('lẻ') || v == 'retail') return 'retail';
    if (v.contains('sỉ') || v == 'wholesale') return 'wholesale';
    if (v.contains('npp') || v.contains('phân phối') || v == 'distributor') return 'distributor';
    if (v.contains('horeca')) return 'horeca';
    if (v.contains('khác') || v == 'other') return 'other';
    return 'retail';
  }

  static String _parseTier(String value) {
    final v = value.toLowerCase();
    if (v.contains('kim') || v == 'diamond') return 'diamond';
    if (v.contains('vàng') || v == 'gold') return 'gold';
    if (v.contains('bạc') || v == 'silver') return 'silver';
    if (v.contains('đồng') || v == 'bronze') return 'bronze';
    return 'bronze';
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class ImportResult {
  final int added;
  final int updated;
  final int skipped;
  final List<String> errors;

  ImportResult({
    required this.added,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  int get total => added + updated + skipped;
  bool get hasErrors => errors.isNotEmpty;
}
