import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/database.dart';
import '../models/asset.dart';
import 'asset_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final DatabaseService _dbService = DatabaseService();

  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;

  // 排序选项
  final List<String> _sortOptions = [
    '购买时间（新到旧）',
    '购买时间（旧到新）',
    '价格（高到低）',
    '价格（低到高）',
    '持有天数（多到少）',
    '持有天数（少到多）',
    '日均成本（高到低）',
    '日均成本（低到高）',
  ];
  String _selectedSort = '购买时间（新到旧）';

  // 筛选相关
  String _searchKeyword = '';
  List<String> _locations = [];
  String? _selectedLocation;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);

    try {
      // 并行加载资产和位置
      final allAssets = await _dbService.getAllAssets();
      final locations = await _dbService.getLocations();

      // 筛选出当前分类的资产
      final filteredAssets = allAssets.where((asset) {
        final assetCategory = asset.category ?? '其他';
        return assetCategory == widget.categoryName;
      }).toList();

      // 应用排序
      _applySorting(filteredAssets);

      setState(() {
        _assets = filteredAssets;
        _filteredAssets = List.from(filteredAssets);
        _locations = locations;
        _isLoading = false;
      });

    } catch (e) {
      print('加载分类资产失败: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applySorting(List<Asset> assets) {
    switch (_selectedSort) {
      case '购买时间（新到旧）':
        assets.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        break;
      case '购买时间（旧到新）':
        assets.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
        break;
      case '价格（高到低）':
        assets.sort((a, b) => b.price.compareTo(a.price));
        break;
      case '价格（低到高）':
        assets.sort((a, b) => a.price.compareTo(b.price));
        break;
      case '持有天数（多到少）':
        assets.sort((a, b) => b.daysOwned.compareTo(a.daysOwned));
        break;
      case '持有天数（少到多）':
        assets.sort((a, b) => a.daysOwned.compareTo(b.daysOwned));
        break;
      case '日均成本（高到低）':
        assets.sort((a, b) => b.dailyCost.compareTo(a.dailyCost));
        break;
      case '日均成本（低到高）':
        assets.sort((a, b) => a.dailyCost.compareTo(b.dailyCost));
        break;
    }
  }

  // 应用筛选
  void _applyFilters() {
    List<Asset> result = List.from(_assets);

    // 关键词搜索
    if (_searchKeyword.isNotEmpty) {
      final keyword = _searchKeyword.toLowerCase();
      result = result.where((asset) {
        return asset.name.toLowerCase().contains(keyword) ||
            (asset.notes != null && asset.notes!.toLowerCase().contains(keyword));
      }).toList();
    }

    // 位置筛选
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      result = result.where((asset) => asset.location == _selectedLocation).toList();
    }

    // 价格范围筛选
    if (_minPrice != null) {
      result = result.where((asset) => asset.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      result = result.where((asset) => asset.price <= _maxPrice!).toList();
    }

    setState(() {
      _filteredAssets = result;
      // 重新应用排序
      _applySorting(_filteredAssets);
    });
  }

  // 显示筛选对话框
  Future<void> _showFilterDialog() async {
    final searchController = TextEditingController(text: _searchKeyword);
    final minPriceController = TextEditingController(
        text: _minPrice?.toString() ?? ''
    );
    final maxPriceController = TextEditingController(
        text: _maxPrice?.toString() ?? ''
    );
    String? tempSelectedLocation = _selectedLocation;

    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选资产'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关键词搜索
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: '关键词搜索',
                  hintText: '输入资产名称或备注',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),

              // 位置筛选
              DropdownButtonFormField<String>(
                value: tempSelectedLocation,
                onChanged: (value) {
                  tempSelectedLocation = value;
                },
                decoration: const InputDecoration(
                  labelText: '位置筛选',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('全部位置'),
                  ),
                  ..._locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 16),

              // 价格范围
              const Text(
                '价格范围（可选）',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minPriceController,
                      decoration: const InputDecoration(
                        labelText: '最低价',
                        hintText: '0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxPriceController,
                      decoration: const InputDecoration(
                        labelText: '最高价',
                        hintText: '不限',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchKeyword = searchController.text.trim();
                _selectedLocation = tempSelectedLocation;
                _minPrice = minPriceController.text.trim().isEmpty
                    ? null
                    : double.tryParse(minPriceController.text.trim());
                _maxPrice = maxPriceController.text.trim().isEmpty
                    ? null
                    : double.tryParse(maxPriceController.text.trim());
              });
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('应用筛选'),
          ),
        ],
      ),
    );

    // 清除筛选
    if (result == 'clear') {
      setState(() {
        _searchKeyword = '';
        _selectedLocation = null;
        _minPrice = null;
        _maxPrice = null;
      });
      _applyFilters();
    }
  }

  // 格式化数字显示
  String _formatNumber(double value, {bool isPrice = true}) {
    if (value >= 1000000) {
      return isPrice ? '¥${(value / 10000).toStringAsFixed(1)}万' : '${(value / 10000).toStringAsFixed(1)}万';
    } else if (value >= 1000) {
      return isPrice ? '¥${value.toStringAsFixed(0)}' : value.toStringAsFixed(0);
    } else {
      return isPrice ? '¥${value.toStringAsFixed(value >= 10 ? 0 : 1)}' : value.toStringAsFixed(value >= 10 ? 0 : 1);
    }
  }

  // 格式化日期显示
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 构建资产卡片
  Widget _buildAssetCard(Asset asset) {
    return Slidable(
      key: ValueKey(asset.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              bool confirm = await _showDeleteConfirmationDialog(asset);
              if (confirm) {
                _deleteAsset(asset.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${asset.name}" 已删除'),
                    action: SnackBarAction(
                      label: '撤销',
                      onPressed: () {
                        _undoDelete(asset);
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(assetId: asset.id),
            ),
          ).then((needRefresh) {
            if (needRefresh == true) {
              _loadAssets();
            }
          });
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 图标区域
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory,
                      color: widget.categoryColor,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 信息区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 资产名称
                        Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // 购买日期和持有天数
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatDate(asset.purchaseDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '持有: ${asset.daysOwnedFormatted}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // 价格和位置
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 购买价格
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatNumber(asset.price),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),

                            // 位置信息
                            if (asset.location != null && asset.location!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      asset.location!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(Asset asset) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除 "${asset.name}" 吗？'),
            const SizedBox(height: 8),
            Text(
              '价格: ${_formatNumber(asset.price)}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '日均成本: ${_formatNumber(asset.dailyCost, isPrice: false)}/天',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return shouldDelete ?? false;
  }

  void _deleteAsset(String id) async {
    await _dbService.softDeleteAsset(id);
    await _loadAssets();
  }

  void _undoDelete(Asset asset) async {
    await _dbService.restoreAsset(asset.id);
    await _loadAssets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已恢复 "${asset.name}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 构建统计摘要 - 修复了这里的问题
  Widget _buildStatsSummary() {
    final count = _filteredAssets.length;
    final totalValue = _filteredAssets.fold<double>(0, (sum, asset) => sum + asset.price);
    final avgValue = count > 0 ? totalValue / count : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: widget.categoryColor.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('资产数', count.toString(), Icons.inventory),
          _buildStatItem('总价值', _formatNumber(totalValue), Icons.attach_money),
          _buildStatItem('平均价', _formatNumber(avgValue), Icons.calculate),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: widget.categoryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: widget.categoryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 构建筛选状态指示器
  Widget _buildFilterIndicator() {
    final List<String> activeFilters = [];

    if (_searchKeyword.isNotEmpty) {
      activeFilters.add('关键词: "$_searchKeyword"');
    }

    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      activeFilters.add('位置: $_selectedLocation');
    }

    if (_minPrice != null) {
      activeFilters.add('最低价: ${_formatNumber(_minPrice!)}');
    }

    if (_maxPrice != null) {
      activeFilters.add('最高价: ${_formatNumber(_maxPrice!)}');
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '已应用筛选: ${activeFilters.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchKeyword = '';
                _selectedLocation = null;
                _minPrice = null;
                _maxPrice = null;
              });
              _applyFilters();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text(
              '清除',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建空状态
  Widget _buildEmptyState() {
    final hasFilters = _searchKeyword.isNotEmpty ||
        (_selectedLocation != null && _selectedLocation!.isNotEmpty) ||
        _minPrice != null ||
        _maxPrice != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off : Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? '没有符合条件的资产' : '${widget.categoryName} 中暂无资产',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters ? '请调整筛选条件' : '可以添加资产时选择此分类',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchKeyword = '';
                    _selectedLocation = null;
                    _minPrice = null;
                    _maxPrice = null;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('清除所有筛选'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 1,
        centerTitle: true,
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '筛选',
          ),
        ],
      ),
      body: Column(
        children: [
          // 排序下拉框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Icon(Icons.sort, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  '排序:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != _selectedSort) {
                        setState(() {
                          _selectedSort = newValue;
                          _applySorting(_filteredAssets);
                        });
                      }
                    },
                    items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    underline: const SizedBox(),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 筛选状态指示器
          _buildFilterIndicator(),

          // 统计摘要
          _buildStatsSummary(),

          // 资产列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssets.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadAssets,
              child: ListView.builder(
                itemCount: _filteredAssets.length,
                itemBuilder: (context, index) {
                  return _buildAssetCard(_filteredAssets[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}