import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../services/database.dart';

class AssetAddScreen extends StatefulWidget {
  final Function(bool)? onComplete;

  const AssetAddScreen({super.key, this.onComplete});

  @override
  State<AssetAddScreen> createState() => _AssetAddScreenState();
}

class _AssetAddScreenState extends State<AssetAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedCategory;
  String? _selectedLocation;
  DateTime _purchaseDate = DateTime.now();

  final DatabaseService _dbService = DatabaseService();
  List<String> _categories = [];
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cats = await _dbService.getCategories();
    final locs = await _dbService.getLocations();
    setState(() {
      _categories = cats;
      _locations = locs;
    });
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 去重函数
  List<String> _deduplicateList(List<String> list) {
    final seen = <String>{};
    final result = <String>[];

    for (var item in list) {
      if (!seen.contains(item)) {
        seen.add(item);
        result.add(item);
      }
    }

    return result;
  }

  Widget _buildDropdown(String label, List<String> options, String? value,
      void Function(String?)? onChanged, {required bool isCategory}) {
    final uniqueOptions = _deduplicateList(options);

    String? safeValue = value;
    if (safeValue != null && !uniqueOptions.contains(safeValue)) {
      safeValue = null;
    }

    if (safeValue == null && uniqueOptions.isNotEmpty) {
      safeValue = uniqueOptions.first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        onChanged: (newValue) {
          setState(() {
            if (isCategory) {
              _selectedCategory = newValue;
            } else {
              _selectedLocation = newValue;
            }
          });
          onChanged?.call(newValue);
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: uniqueOptions.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState?.validate() != true) return;

    final newAsset = Asset(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      purchaseDate: _purchaseDate,
      category: _selectedCategory,
      location: _selectedLocation,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await _dbService.insertAsset(newAsset);

      if (widget.onComplete != null) {
        widget.onComplete!(true); // 通知主框架添加完成
      } else {
        // 如果没有回调，直接返回
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '资产名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '请输入资产名称'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '购买价格（¥）',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入价格';
                }
                if (double.tryParse(value.trim()) == null) {
                  return '请输入有效数字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              '类别',
              _categories,
              _selectedCategory,
                  (value) => setState(() => _selectedCategory = value),
              isCategory: true,
            ),
            const SizedBox(height: 16),

            _buildDropdown(
              '位置',
              _locations,
              _selectedLocation,
                  (value) => setState(() => _selectedLocation = value),
              isCategory: false,
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _selectPurchaseDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: '购买日期',
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd').format(_purchaseDate),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAsset,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  if (widget.onComplete != null) {
                    widget.onComplete!(false); // 取消添加
                  } else {
                    Navigator.pop(context, false);
                  }
                },
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}