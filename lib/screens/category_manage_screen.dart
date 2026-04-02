import 'package:flutter/material.dart';
import '../services/database.dart';

class CategoryManageScreen extends StatefulWidget {
  final List<String> categories;
  final VoidCallback? onCategoriesUpdated;

  const CategoryManageScreen({
    super.key,
    required this.categories,
    this.onCategoriesUpdated,
  });

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  late List<String> _categories;
  final DatabaseService _db = DatabaseService();
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  // 添加分类
  Future<void> _addCategory() async {
    _addController.clear();
    final String? newCategory = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("添加分类"),
        content: TextField(
          controller: _addController,
          decoration: const InputDecoration(
            hintText: "请输入分类名称",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_addController.text.trim().isNotEmpty) {
                Navigator.pop(context, _addController.text.trim());
              }
            },
            child: const Text("添加"),
          ),
        ],
      ),
    );

    if (newCategory != null) {
      // 检查是否已存在
      if (_categories.contains(newCategory)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分类 "$newCategory" 已存在'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _categories.add(newCategory);
      });

      await _db.saveCategories(_categories);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加分类 "$newCategory"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      widget.onCategoriesUpdated?.call();
    }
  }

  // 编辑分类
  Future<void> _editCategory(int index) async {
    _editController.text = _categories[index];

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("编辑分类"),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(
            hintText: "请输入新名称",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_editController.text.trim().isNotEmpty) {
                Navigator.pop(context, _editController.text.trim());
              }
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );

    if (newName != null && newName != _categories[index]) {
      // 检查是否已存在
      if (_categories.contains(newName)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分类 "$newName" 已存在'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _categories[index] = newName;
      });

      await _db.saveCategories(_categories);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分类已更新为 "$newName"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      widget.onCategoriesUpdated?.call();
    }
  }

  // 删除分类
  Future<void> _deleteCategory(int index) async {
    final categoryName = _categories[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text(
          '确定要删除分类 "$categoryName" 吗？\n\n'
              '注意：如果资产正在使用此分类，删除后资产将显示为"无分类"。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("删除", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _categories.removeAt(index);
      });

      await _db.saveCategories(_categories);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除分类 "$categoryName"'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onCategoriesUpdated?.call();
    }
  }

  // 排序
  void _sortCategories() {
    setState(() {
      _categories.sort((a, b) => a.compareTo(b));
    });
    _db.saveCategories(_categories);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已按字母顺序排序'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("分类管理"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            onPressed: _sortCategories,
            tooltip: "排序",
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("添加新分类"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 分类列表
          Expanded(
            child: _categories.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    final category = _categories[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.category, color: Colors.blue),
        ),
        title: Text(
          category,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _editCategory(index),
              tooltip: "编辑",
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deleteCategory(index),
              tooltip: "删除",
            ),
          ],
        ),
      ),
    );
  }

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
            "点击下方按钮添加第一个分类",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}