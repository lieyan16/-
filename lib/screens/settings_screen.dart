import 'package:flutter/material.dart';
import '../services/database.dart';
import 'category_manage_screen.dart';
import 'location_manage_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _categories = [];
  List<String> _locations = [];
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cats = await _db.getCategories();
    final locs = await _db.getLocations();
    setState(() {
      _categories = cats;
      _locations = locs;
    });
  }

  // 统计卡片
  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count 个',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置"),  // 这里改为"设置"，去掉"软件"两字
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 数据管理标题
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: const Text(
              "数据管理",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),

          // 分类管理
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryManageScreen(
                    categories: _categories,
                    onCategoriesUpdated: () {
                      _loadSettings();
                    },
                  ),
                ),
              );
            },
            child: _buildStatCard(
              "分类管理",
              _categories.length,
              Icons.category,
              Colors.blue,
            ),
          ),

          // 位置管理
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationManageScreen(
                    locations: _locations,
                    onLocationsUpdated: () {
                      _loadSettings();
                    },
                  ),
                ),
              );
            },
            child: _buildStatCard(
              "位置管理",
              _locations.length,
              Icons.location_on,
              Colors.green,
            ),
          ),

          // 标签管理（预留）
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('标签管理功能开发中...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Opacity(
              opacity: 0.6,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(Icons.tag, color: Colors.purple),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "标签管理",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '开发中',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 其他设置标题
          Container(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
            child: const Text(
              "其他设置",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),

          // 备份与同步（预留）
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.orange),
              ),
              title: const Text("备份与同步"),
              subtitle: const Text("开发中"),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('备份与同步功能开发中...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),

          // 关于软件
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.info, color: Colors.grey),
              ),
              title: const Text("关于软件"),
              subtitle: const Text("版本 1.0.0"),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("关于软件"),
                    content: const Text(
                      "我的资产管理系统\n版本：1.0.0\n\n一款简单实用的资产管理工具，帮你记录和统计个人资产。\n开发者：烈焰\n反馈邮箱：lieyan16@qq.com",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("确定"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // 数据统计
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📊 数据统计",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("分类数量", "${_categories.length}个"),
                    _buildStatItem("位置数量", "${_locations.length}个"),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  "💡 小贴士",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "分类和位置信息会在添加资产时使用，合理的分类能帮你更好地管理资产。",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}