import 'package:flutter/material.dart';
import '../services/database.dart';

class LocationManageScreen extends StatefulWidget {
  final List<String> locations;
  final VoidCallback? onLocationsUpdated;

  const LocationManageScreen({
    super.key,
    required this.locations,
    this.onLocationsUpdated,
  });

  @override
  State<LocationManageScreen> createState() => _LocationManageScreenState();
}

class _LocationManageScreenState extends State<LocationManageScreen> {
  late List<String> _locations;
  final DatabaseService _db = DatabaseService();
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _locations = List.from(widget.locations);
  }

  // 添加位置
  Future<void> _addLocation() async {
    _addController.clear();
    final String? newLocation = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("添加位置"),
        content: TextField(
          controller: _addController,
          decoration: const InputDecoration(
            hintText: "请输入位置名称",
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

    if (newLocation != null) {
      // 检查是否已存在
      if (_locations.contains(newLocation)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('位置 "$newLocation" 已存在'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _locations.add(newLocation);
      });

      await _db.saveLocations(_locations);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加位置 "$newLocation"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      widget.onLocationsUpdated?.call();
    }
  }

  // 编辑位置
  Future<void> _editLocation(int index) async {
    _editController.text = _locations[index];

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("编辑位置"),
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

    if (newName != null && newName != _locations[index]) {
      // 检查是否已存在
      if (_locations.contains(newName)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('位置 "$newName" 已存在'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _locations[index] = newName;
      });

      await _db.saveLocations(_locations);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('位置已更新为 "$newName"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      widget.onLocationsUpdated?.call();
    }
  }

  // 删除位置
  Future<void> _deleteLocation(int index) async {
    final locationName = _locations[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text(
          '确定要删除位置 "$locationName" 吗？\n\n'
              '注意：如果资产正在使用此位置，删除后资产将显示为"无位置"。',
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
        _locations.removeAt(index);
      });

      await _db.saveLocations(_locations);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除位置 "$locationName"'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onLocationsUpdated?.call();
    }
  }

  // 排序
  void _sortLocations() {
    setState(() {
      _locations.sort((a, b) => a.compareTo(b));
    });
    _db.saveLocations(_locations);
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
        title: const Text("位置管理"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            onPressed: _sortLocations,
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
                    onPressed: _addLocation,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("添加新位置"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 位置列表
          Expanded(
            child: _locations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                return _buildLocationItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(int index) {
    final location = _locations[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.location_on, color: Colors.green),
        ),
        title: Text(
          location,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _editLocation(index),
              tooltip: "编辑",
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deleteLocation(index),
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
            Icons.location_on_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          const Text(
            "暂无位置",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "点击下方按钮添加第一个位置",
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