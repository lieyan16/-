import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_photo.dart';
import '../services/database.dart';
import '../services/image_manager.dart';
import '../widgets/image_picker_widget.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ImageManager _imageManager = ImageManager();
  final _formKey = GlobalKey<FormState>();

  // 控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // 下拉框值
  String? _selectedCategory;
  String? _selectedLocation;

  // 数据
  List<String> _categories = [];
  List<String> _locations = [];
  Asset? _asset;
  List<AssetPhoto> _assetPhotos = [];
  bool _isLoading = true;
  bool _isEditing = false;
  DateTime _purchaseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 分别加载数据
      final asset = await _dbService.getAssetById(widget.assetId);

      if (asset != null) {
        // 并行加载分类、位置和图片
        final categories = await _dbService.getCategories();
        final locations = await _dbService.getLocations();
        final photos = await _imageManager.getPhotosForAsset(widget.assetId);

        setState(() {
          _asset = asset;
          _categories = categories;
          _locations = locations;
          _assetPhotos = photos;

          // 填充表单数据
          _nameController.text = asset.name;
          _priceController.text = asset.price.toString();
          _selectedCategory = asset.category;
          _selectedLocation = asset.location;
          _notesController.text = asset.notes ?? '';
          _purchaseDate = asset.purchaseDate;
          _dateController.text = DateFormat('yyyy-MM-dd').format(asset.purchaseDate);

          _isLoading = false;
        });
      } else {
        // 资产不存在
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资产不存在或已被删除')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('加载详情失败: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_asset == null) return;

    final updatedAsset = Asset(
      id: _asset!.id,
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      purchaseDate: _purchaseDate,
      category: _selectedCategory,
      location: _selectedLocation,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imageUrl: _asset!.imageUrl,
      iconName: _asset!.iconName,
      createdAt: _asset!.createdAt,
      updatedAt: DateTime.now(),
      isDeleted: false,
      version: _asset!.version,
    );

    try {
      await _dbService.updateAsset(updatedAsset);

      if (!mounted) return;

      // 保存成功后退出编辑模式
      setState(() {
        _isEditing = false;
      });

      // 重新加载数据
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('资产已更新'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  Future<void> _deleteAsset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个资产吗？删除后可以在列表页撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.softDeleteAsset(widget.assetId);
      if (!mounted) return;

      // 清理资产图片
      await _cleanupAssetPhotos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('资产已删除'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              _undoDelete();
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true); // 返回并刷新列表
    }
  }

  Future<void> _cleanupAssetPhotos() async {
    try {
      // 删除本地图片文件
      for (final photo in _assetPhotos) {
        await _imageManager.deleteImage(photo);
      }
    } catch (e) {
      print('清理资产图片失败: $e');
    }
  }

  Future<void> _undoDelete() async {
    await _dbService.restoreAsset(widget.assetId);
    await _loadData();
  }

  Widget _buildIcon(String? category) {
    if (category == null || category.isEmpty) {
      return const Icon(Icons.category, color: Colors.blue, size: 40);
    }

    final low = category.toLowerCase();
    if (low.contains('手机') || low.contains('phone') || low.contains('电子')) {
      return const Icon(Icons.phone_iphone, color: Colors.blue, size: 40);
    } else if (low.contains('电脑') || low.contains('笔记本') || low.contains('laptop')) {
      return const Icon(Icons.laptop, color: Colors.purple, size: 40);
    } else if (low.contains('相机') || low.contains('摄影') || low.contains('camera')) {
      return const Icon(Icons.camera_alt, color: Colors.green, size: 40);
    } else if (low.contains('硬盘') || low.contains('存储') || low.contains('ssd')) {
      return const Icon(Icons.sd_storage, color: Colors.orange, size: 40);
    } else if (low.contains('耳机') || low.contains('音响')) {
      return const Icon(Icons.headphones, color: Colors.cyan, size: 40);
    } else {
      return const Icon(Icons.category, color: Colors.blue, size: 40);
    }
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.green : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 去重函数（安全处理重复项）
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

  Widget _buildEditField(String label, TextEditingController controller,
      {String? Function(String?)? validator, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  // 修复后的下拉框组件 - 确保选项唯一
  Widget _buildDropdown(String label, List<String> options, String? value,
      void Function(String?)? onChanged, {required bool isCategory}) {
    // 确保选项唯一
    final uniqueOptions = _deduplicateList(options);

    // 确保选中的值在选项中
    String? safeValue = value;
    if (safeValue != null && !uniqueOptions.contains(safeValue)) {
      safeValue = null;
    }

    // 如果没有选中值且列表不为空，选择第一个
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

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectPurchaseDate,
      child: AbsorbPointer(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: '购买日期',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
        ),
      ),
    );
  }

  // 构建图片画廊
  Widget _buildImageGallery() {
    if (_assetPhotos.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          '图片附件',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _assetPhotos.length,
          itemBuilder: (context, index) {
            final photo = _assetPhotos[index];
            return GestureDetector(
              onTap: () => _viewImageFullScreen(index),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: photo.thumbnailPath != null
                          ? Image.file(
                        File(photo.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  if (photo.description != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          photo.description!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '共 ${_assetPhotos.length} 张图片，点击查看大图',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 查看全屏图片
  Future<void> _viewImageFullScreen(int index) async {
    final photo = _assetPhotos[index];

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            // 全屏图片查看器
            Container(
              color: Colors.black,
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(photo.filePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // 关闭按钮
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // 底部信息栏
            if (photo.description != null || photo.fileName != null)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photo.description != null)
                        Text(
                          photo.description!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (photo.fileName != null)
                        Text(
                          '文件名: ${photo.fileName}',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                          ),
                        ),
                      Text(
                        '大小: ${(photo.fileSize / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    if (_asset == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标和标题
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(child: _buildIcon(_asset!.category)),
                ),
                const SizedBox(height: 16),
                Text(
                  _asset!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_asset!.category != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(_asset!.category!),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // 基本信息
          _buildInfoRow('资产名称', _asset!.name),
          _buildInfoRow('购买价格', '¥${_asset!.price.toStringAsFixed(2)}'),
          _buildInfoRow('购买日期', _asset!.purchaseDateFormatted),
          if (_asset!.location != null)
            _buildInfoRow('存放位置', _asset!.location!),

          // 计算信息
          const SizedBox(height: 16),
          const Text(
            '计算信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          _buildInfoRow('持有天数', _asset!.daysOwnedFormatted),
          _buildInfoRow('日均成本', '¥${_asset!.dailyCost.toStringAsFixed(2)}/天', highlight: true),

          // 图片附件
          _buildImageGallery(),

          // 备注
          if (_asset!.notes != null && _asset!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '备注',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(_asset!.notes!),
            ),
          ],

          // 元数据
          const SizedBox(height: 24),
          const Divider(),
          _buildInfoRow('创建时间', DateFormat('yyyy-MM-dd HH:mm').format(_asset!.createdAt)),
          _buildInfoRow('最后更新', DateFormat('yyyy-MM-dd HH:mm').format(_asset!.updatedAt)),
          _buildInfoRow('版本号', _asset!.version.toString()),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEditView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEditField(
              '资产名称',
              _nameController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? '请输入资产名称'
                  : null,
            ),

            _buildEditField(
              '购买价格（¥）',
              _priceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '请输入价格';
                if (double.tryParse(value.trim()) == null) return '请输入有效数字';
                return null;
              },
            ),

            // 使用修复后的下拉框
            _buildDropdown(
              '分类',
              _categories,
              _selectedCategory,
                  (value) {
                setState(() => _selectedCategory = value);
              },
              isCategory: true,
            ),

            // 使用修复后的下拉框
            _buildDropdown(
              '位置',
              _locations,
              _selectedLocation,
                  (value) {
                setState(() => _selectedLocation = value);
              },
              isCategory: false,
            ),

            _buildDatePicker(),

            _buildEditField('备注（可选）', _notesController),

            const SizedBox(height: 24),

            // 图片选择器
            ImagePickerWidget(
              assetId: widget.assetId,
              initialImages: _assetPhotos,
              onImagesChanged: (List<AssetPhoto> photos) {
                setState(() {
                  _assetPhotos = photos;
                });
              },
              maxImages: 10,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  '保存修改',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                },
                child: const Text('取消编辑'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('资产详情'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑资产' : '资产详情'),
        actions: _isEditing
            ? [] // 编辑模式下不显示编辑按钮
            : [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() => _isEditing = true);
            },
            tooltip: '编辑',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteAsset();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除资产'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isEditing ? _buildEditView() : _buildDetailView(),
    );
  }
}