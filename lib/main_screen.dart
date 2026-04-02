import 'package:flutter/material.dart';
import 'screens/asset_list_screen.dart';
import 'screens/asset_add_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/category_overview_screen.dart';  // 导入分类总览页面

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showAddPage = false;
  bool _showCategoryPage = false;  // 控制是否显示分类页面

  // 主页面列表
  final List<Widget> _pages = [
    const AssetListScreen(),
    Container(), // 占位，实际不会显示（用于添加页面）
    const SettingsScreen(),
  ];

  // 页面标题
  final List<String> _pageTitles = [
    '我的资产',
    '添加资产',
    '设置',
  ];

  // 导航项图标
  final List<IconData> _navIcons = [
    Icons.home,
    Icons.add,
    Icons.settings,
  ];

  // 导航项标签
  final List<String> _navLabels = [
    '主页',
    '添加',
    '设置',
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // 中间按钮：显示添加页面
      setState(() {
        _showAddPage = true;
        _showCategoryPage = false;  // 确保分类页面关闭
      });
    } else {
      // 其他按钮：切换页面
      setState(() {
        _selectedIndex = index;
        _showAddPage = false;
        _showCategoryPage = false;  // 确保分类页面关闭
      });
    }
  }

  // 打开分类页面
  void _openCategoryPage() {
    setState(() {
      _showCategoryPage = true;
    });
  }

  // 从添加页面返回时的回调
  void _onAddComplete(bool needRefresh) {
    setState(() {
      _showAddPage = false;
      _selectedIndex = 0; // 返回主页
      _showCategoryPage = false;  // 确保分类页面关闭
    });

    // 如果需要刷新，可以通过回调通知资产列表刷新
    // 这里我们稍后会通过其他方式实现
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showAddPage
          ? AppBar(
        title: const Text('添加资产'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showAddPage = false;
              _selectedIndex = 0;
              _showCategoryPage = false;
            });
          },
        ),
      )
          : _showCategoryPage
          ? AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showCategoryPage = false;
            });
          },
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        centerTitle: true,
      )
          : AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        centerTitle: true,
        // 只在资产列表页面显示分类图标
        actions: _selectedIndex == 0 && !_showAddPage && !_showCategoryPage
            ? [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _openCategoryPage,
            tooltip: '分类查看',
          ),
        ]
            : null,
      ),
      body: _showAddPage
          ? AssetAddScreen(onComplete: _onAddComplete)
          : _showCategoryPage
          ? const CategoryOverviewScreen()
          : _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(_navIcons[0]),
            label: _navLabels[0],
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _navIcons[1],
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            label: _navLabels[1],
          ),
          BottomNavigationBarItem(
            icon: Icon(_navIcons[2]),
            label: _navLabels[2],
            backgroundColor: Colors.white,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        onTap: _onItemTapped,
      ),
    );
  }
}