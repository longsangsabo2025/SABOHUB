import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/manufacturing_service.dart';
import '../../models/manufacturing_models.dart';

class BOMPage extends ConsumerStatefulWidget {
  const BOMPage({super.key});

  @override
  ConsumerState<BOMPage> createState() => _BOMPageState();
}

class _BOMPageState extends ConsumerState<BOMPage> {
  final _service = ManufacturingService();
  List<BOM> _boms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBOMs();
  }

  Future<void> _loadBOMs() async {
    setState(() => _loading = true);
    try {
      final boms = await _service.getBOMs();
      setState(() {
        _boms = boms;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải BOM: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Định Mức Nguyên Liệu (BOM)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBOMs,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _boms.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có định mức nguyên liệu'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _boms.length,
                  itemBuilder: (context, index) {
                    final bom = _boms[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(bom.bomCode[0]),
                        ),
                        title: Text(bom.name ?? bom.bomCode),
                        subtitle: Text('Phiên bản: ${bom.version} • ${bom.status == "active" ? "Đang dùng" : bom.status}'),
                        trailing: bom.isDefault
                            ? const Icon(Icons.star, color: Colors.amber)
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm BOM - Coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
