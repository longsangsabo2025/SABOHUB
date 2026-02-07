// Barcode Scanner Widget for Odori Products
// Uses mobile_scanner package for barcode scanning

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../business_types/distribution/models/odori_models.dart';
import '../business_types/distribution/services/odori_service.dart';

/// A widget that provides barcode scanning functionality
/// Can be used for product lookup in orders, inventory, etc.
class BarcodeScannerWidget extends StatefulWidget {
  final Function(OdoriProduct product) onProductFound;
  final Function(String barcode)? onBarcodeScanned;
  final Function(String error)? onError;
  final bool autoClose;

  const BarcodeScannerWidget({
    super.key,
    required this.onProductFound,
    this.onBarcodeScanned,
    this.onError,
    this.autoClose = true,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  OdoriProduct? _foundProduct;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _searchByBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _foundProduct = null;
    });

    widget.onBarcodeScanned?.call(barcode);

    try {
      final product = await odoriService.getProductByBarcode(barcode);
      
      if (product != null) {
        setState(() {
          _foundProduct = product;
          _isLoading = false;
        });
        widget.onProductFound(product);
        
        if (widget.autoClose && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.of(context).pop(product);
        }
      } else {
        setState(() {
          _error = 'Không tìm thấy sản phẩm với mã: $barcode';
          _isLoading = false;
        });
        widget.onError?.call(_error!);
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tìm kiếm: $e';
        _isLoading = false;
      });
      widget.onError?.call(_error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Manual barcode input
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã vạch...',
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: _searchByBarcode,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading 
                    ? null 
                    : () => _searchByBarcode(_barcodeController.text),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
        ),

        // Camera scanner placeholder
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Scanner frame
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Corner decorations
              Positioned(
                top: 25,
                left: 25,
                child: _buildCorner(true, true),
              ),
              Positioned(
                top: 25,
                right: 25,
                child: _buildCorner(true, false),
              ),
              Positioned(
                bottom: 25,
                left: 25,
                child: _buildCorner(false, true),
              ),
              Positioned(
                bottom: 25,
                right: 25,
                child: _buildCorner(false, false),
              ),
              // Scanning line animation
              const Positioned(
                bottom: 8,
                child: Text(
                  'Đặt mã vạch trong khung hoặc nhập thủ công',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              // Info text for demo mode
              const Text(
                '📷 Camera Scanner\n(Cần cài đặt mobile_scanner)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),

        // Result display
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_foundProduct != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundProduct!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_foundProduct!.sku ?? ''} • ${_foundProduct!.formattedPrice}/${_foundProduct!.unit}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.orange, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.orange, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.orange, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.orange, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}

/// Dialog wrapper for barcode scanner
class BarcodeScannerDialog extends StatelessWidget {
  final Function(OdoriProduct product) onProductFound;
  
  const BarcodeScannerDialog({
    super.key,
    required this.onProductFound,
  });

  static Future<OdoriProduct?> show(BuildContext context) async {
    return showModalBottomSheet<OdoriProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Quét mã vạch sản phẩm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Scanner widget
              BarcodeScannerWidget(
                onProductFound: (product) {
                  // Will auto-close and return product
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerWidget(onProductFound: onProductFound);
  }
}

/// Quick scan button widget
class QuickScanButton extends StatelessWidget {
  final Function(OdoriProduct product) onProductScanned;
  final bool mini;

  const QuickScanButton({
    super.key,
    required this.onProductScanned,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return IconButton(
        onPressed: () => _openScanner(context),
        icon: const Icon(Icons.qr_code_scanner),
        tooltip: 'Quét mã vạch',
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _openScanner(context),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Quét mã'),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final product = await BarcodeScannerDialog.show(context);
    if (product != null) {
      onProductScanned(product);
    }
  }
}
