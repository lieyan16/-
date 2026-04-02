import 'package:flutter/material.dart';
import 'services/database.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  print('🚀 正在初始化数据库...');
  final dbService = DatabaseService();
  await dbService.database;
  print('✅ 数据库初始化完成！');

  // 打印当前资产数量（调试用）
  final assets = await dbService.getAllAssets();
  print('📊 当前共有 ${assets.length} 条资产：');
  if (assets.isEmpty) {
    print('   当前没有资产，显示空状态');
  } else {
    for (var asset in assets) {
      print('   - ${asset.name} (¥${asset.price})');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的资产管理系统',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(), // 使用新的主框架
      debugShowCheckedModeBanner: false,
    );
  }
}