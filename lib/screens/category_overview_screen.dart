import 'package:flutter/material.dart';
import '../services/database.dart';
import '../models/asset.dart';
import 'category_detail_screen.dart';

class CategoryOverviewScreen extends StatefulWidget {
  const CategoryOverviewScreen({super.key});

  @override
  State<CategoryOverviewScreen> createState() => _CategoryOverviewScreenState();
}

class _CategoryOverviewScreenState extends State<CategoryOverviewScreen> {
  final DatabaseService _dbService = DatabaseService();

  List<String> _categories = [];
  Map<String, int> _categoryCounts = {};
  bool _isLoading = true;

  // 默认分类配置
  final List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': '电子产品/手机',
      'icon': Icons.phone_iphone,
      'color': Colors.blue,
    },
    {
      'name': '电子产品/电脑',
      'icon': Icons.laptop,
      'color': Colors.purple,
    },
    {
      'name': '摄影设备',
      'icon': Icons.camera_alt,
      'color': Colors.green,
    },
    {
      'name': '存储设备',
      'icon': Icons.sd_storage,
      'color': Colors.orange,
    },
    {
      'name': '耳机音响',
      'icon': Icons.headphones,
      'color': Colors.cyan,
    },
    {
      'name': '其他',
      'icon': Icons.category,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    setState(() => _isLoading = true);

    try {
      // 加载所有分类
      final categories = await _dbService.getCategories();
      setState(() {
        _categories = categories.isNotEmpty
            ? categories
            : _defaultCategories.map((cat) => cat['name'] as String).toList();
      });

      // 加载所有资产并统计数量
      final allAssets = await _dbService.getAllAssets();
      final Map<String, int> counts = {};

      for (var asset in allAssets) {
        final category = asset.category ?? '其他';
        counts[category] = (counts[category] ?? 0) + 1;
      }

      // 确保所有分类都有计数
      for (var category in _categories) {
        if (!counts.containsKey(category)) {
          counts[category] = 0;
        }
      }

      setState(() {
        _categoryCounts = counts;
        _isLoading = false;
      });

    } catch (e) {
      print('加载分类数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  // 获取分类图标
  Widget _getCategoryIcon(String category) {
    for (var defaultCat in _defaultCategories) {
      if (defaultCat['name'] == category) {
        return Icon(
          defaultCat['icon'] as IconData,
          color: defaultCat['color'] as Color,
          size: 28,
        );
      }
    }

    // 根据分类名称猜测图标
    final low = category.toLowerCase();
    if (low.contains('手机') || low.contains('phone') || low.contains('iphone')) {
      return const Icon(Icons.phone_iphone, color: Colors.blue, size: 28);
    } else if (low.contains('电脑') || low.contains('笔记本') || low.contains('laptop')) {
      return const Icon(Icons.laptop, color: Colors.purple, size: 28);
    } else if (low.contains('相机') || low.contains('摄影') || low.contains('camera')) {
      return const Icon(Icons.camera_alt, color: Colors.green, size: 28);
    } else if (low.contains('硬盘') || low.contains('存储') || low.contains('ssd')) {
      return const Icon(Icons.sd_storage, color: Colors.orange, size: 28);
    } else if (low.contains('耳机') || low.contains('音响')) {
      return const Icon(Icons.headphones, color: Colors.cyan, size: 28);
    } else {
      return const Icon(Icons.category, color: Colors.blue, size: 28);
    }
  }

  // 获取分类颜色
  Color _getCategoryColor(String category) {
    for (var defaultCat in _defaultCategories) {
      if (defaultCat['name'] == category) {
        return defaultCat['color'] as Color;
      }
    }

    final low = category.toLowerCase();
    if (low.contains('手机') || low.contains('phone') || low.contains('iphone')) {
      return Colors.blue;
    } else if (low.contains('电脑') || low.contains('笔记本') || low.contains('laptop')) {
      return Colors.purple;
    } else if (low.contains('相机') || low.contains('摄影') || low.contains('camera')) {
      return Colors.green;
    } else if (low.contains('硬盘') || low.contains('存储') || low.contains('ssd')) {
      return Colors.orange;
    } else if (low.contains('耳机') || low.contains('音响')) {
      return Colors.cyan;
    } else {
      return Colors.grey;
    }
  }

  // 计算网格列数（响应式设计）
  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return 3;
    return 2;
  }

  // 构建分类卡片
  Widget _buildCategoryCard(BuildContext context, String category) {
    final assetsCount = _categoryCounts[category] ?? 0;
    final categoryColor = _getCategoryColor(category);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // 跳转到分类详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(
                categoryName: category,
                categoryColor: categoryColor,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 120, // 固定高度，保持正方形
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: categoryColor.withOpacity(0.1),
            border: Border.all(
              color: categoryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(child: _getCategoryIcon(category)),
              ),

              const SizedBox(height: 12),

              // 分类名称
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // 资产数量
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$assetsCount个',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            "暂无分类",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "请先在设置中添加分类",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
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
        title: const Text('分类总览'),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadCategoryData,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getColumnCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0, // 正方形卡片
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(context, _categories[index]);
            },
          ),
        ),
      ),
    );
  }
}