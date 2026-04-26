import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class CsvUploadPreview extends StatefulWidget {
  final List<List<dynamic>> rows;
  final String phone;
  final Function(List<Map<String, dynamic>>) onConfirm;

  const CsvUploadPreview({
    super.key,
    required this.rows,
    required this.phone,
    required this.onConfirm,
  });

  @override
  State<CsvUploadPreview> createState() => _CsvUploadPreviewState();
}

class _CsvUploadPreviewState extends State<CsvUploadPreview> {
  late List<String> _headers;
  late List<Map<String, dynamic>> _validData;
  bool _hasErrors = false;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  void _processData() {
    if (widget.rows.isEmpty) {
      _hasErrors = true;
      return;
    }

    _headers = widget.rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    _validData = [];

    // required columns
    final requiredColumns = ['registration_number', 'vehicle_type'];
    final missingColumns = requiredColumns.where((col) => !_headers.contains(col)).toList();

    if (missingColumns.isNotEmpty) {
      _hasErrors = true;
      return;
    }

    for (int i = 1; i < widget.rows.length; i++) {
      final row = widget.rows[i];
      if (row.length != _headers.length) continue; // skip malformed row

      final Map<String, dynamic> rowData = {};
      for (int j = 0; j < _headers.length; j++) {
        rowData[_headers[j]] = row[j];
      }
      
      // Basic validation
      if (rowData['registration_number'] == null || rowData['registration_number'].toString().isEmpty) {
        continue; // skip rows without registration number
      }

      _validData.add({
        'registration_number': rowData['registration_number'].toString(),
        'vehicle_type': rowData['vehicle_type']?.toString() ?? 'truck',
        'capacity_tons': double.tryParse(rowData['capacity_tons']?.toString() ?? '') ?? 0,
        'max_load_weight_kg': double.tryParse(rowData['max_load_weight_kg']?.toString() ?? '') ?? 0,
        'status': rowData['status']?.toString() ?? 'active',
        'availability_status': rowData['availability_status']?.toString() ?? 'available',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CSV Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: _hasErrors
            ? const Text('Invalid CSV format. Ensure columns include "registration_number" and "vehicle_type".')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found ${_validData.length} valid rows.'),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Required fields: registration_number, vehicle_type, capacity_tons, max_load_weight_kg, status, availability_status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _validData.length > 5 ? 5 : _validData.length,
                      itemBuilder: (ctx, idx) {
                        final item = _validData[idx];
                        return ListTile(
                          dense: true,
                          title: Text(item['registration_number']),
                          subtitle: Text(item['vehicle_type']),
                        );
                      },
                    ),
                  ),
                  if (_validData.length > 5)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('... and more'),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_hasErrors)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              widget.onConfirm(_validData);
            },
            child: const Text('Confirm Upload'),
          ),
      ],
    );
  }
}
