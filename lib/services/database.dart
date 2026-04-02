import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/asset.dart';
import '../models/asset_image.dart'; // 添加这行

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'my_assets.db');
    return openDatabase(
      path,
      version: 5, // 更新版本号为5
      onConfigure: (db) async => db.execute("PRAGMA foreign_keys = ON"),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ----------------------------- 创建表 -----------------------------
  Future<void> _onCreate(Database db, int version) async {
    // 资产表
    await db.execute("""
      CREATE TABLE assets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        price REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        image_url TEXT,
        icon_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0,1)),
        version INTEGER NOT NULL DEFAULT 1
      )
    """);

    // 加索引
    await db.execute('CREATE INDEX idx_assets_updated ON assets (updated_at)');
    await db.execute('CREATE INDEX idx_assets_deleted ON assets (is_deleted)');

    // 资产图片表
    await db.execute("""
      CREATE TABLE asset_images (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
      )
    """);

    // 为图片表加索引
    await db.execute('CREATE INDEX idx_images_asset ON asset_images (asset_id)');
    await db.execute('CREATE INDEX idx_images_created ON asset_images (created_at)');

    // 设置表（存分类、位置等 JSON 数据）
    await db.execute("""
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    """);

    // 默认分类（确保没有重复）
    await db.insert("settings", {
      "key": "categories",
      "value": jsonEncode([
        "电子产品/手机",
        "电子产品/电脑",
        "摄影设备",
        "存储设备",
        "耳机音响",
        "其他",
      ]),
    });

    // 默认位置（确保没有重复）
    await db.insert("settings", {
      "key": "locations",
      "value": jsonEncode([
        "家里",
        "公司",
        "身上",
        "储物柜",
      ]),
    });

    // 默认示例资产
    final sample = Asset(
      name: "示例 iPhone",
      price: 5999.0,
      purchaseDate: DateTime.now().subtract(const Duration(days: 180)),
      category: "电子产品/手机",
      location: "身上",
      notes: "这是示例资产，长按可删除",
    );
    await db.insert("assets", sample.toMap());
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本2：添加设置表
    if (oldVersion < 3) {
      await db.execute("""
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      """);
    }

    // 版本3：修复重复设置数据
    if (oldVersion < 4) {
      await _fixDuplicateSettings(db);
    }

    // 版本4：添加图片表（版本4到5的升级）
    if (oldVersion < 5) {
      await _upgradeToVersion5(db);
    }
  }

  // 升级到版本5：添加图片表和图标字段
  Future<void> _upgradeToVersion5(Database db) async {
    // 添加图标字段到assets表
    try {
      await db.execute("""
        ALTER TABLE assets ADD COLUMN icon_name TEXT
      """);
    } catch (e) {
      print('添加icon_name字段可能已存在: $e');
    }

    // 创建资产图片表
    await db.execute("""
      CREATE TABLE IF NOT EXISTS asset_images (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
      )
    """);

    // 为图片表加索引
    await db.execute('CREATE INDEX IF NOT EXISTS idx_images_asset ON asset_images (asset_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_images_created ON asset_images (created_at)');
  }

  // ----------------------------- 修复重复设置数据 -----------------------------
  Future<void> _fixDuplicateSettings(Database db) async {
    // 修复分类重复
    final categoriesRes = await db.query("settings", where: "key='categories'");
    if (categoriesRes.isNotEmpty) {
      final raw = categoriesRes.first["value"] as String;
      final list = List<String>.from(jsonDecode(raw));
      final uniqueList = _deduplicateList(list);

      await db.update(
        "settings",
        {"value": jsonEncode(uniqueList)},
        where: "key='categories'",
      );
    }

    // 修复位置重复
    final locationsRes = await db.query("settings", where: "key='locations'");
    if (locationsRes.isNotEmpty) {
      final raw = locationsRes.first["value"] as String;
      final list = List<String>.from(jsonDecode(raw));
      final uniqueList = _deduplicateList(list);

      await db.update(
        "settings",
        {"value": jsonEncode(uniqueList)},
        where: "key='locations'",
      );
    }
  }

  // 去重函数（保持顺序）
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

  // ----------------------------- 分类/位置设置 -----------------------------
  Future<List<String>> getCategories() async {
    final db = await database;
    final res = await db.query("settings", where: "key='categories'");
    if (res.isEmpty) return [];
    final raw = res.first["value"] as String;
    final list = List<String>.from(jsonDecode(raw));
    return _deduplicateList(list); // 确保返回去重后的列表
  }

  Future<List<String>> getLocations() async {
    final db = await database;
    final res = await db.query("settings", where: "key='locations'");
    if (res.isEmpty) return [];
    final raw = res.first["value"] as String;
    final list = List<String>.from(jsonDecode(raw));
    return _deduplicateList(list); // 确保返回去重后的列表
  }

  Future<void> saveCategories(List<String> list) async {
    final db = await database;
    final uniqueList = _deduplicateList(list); // 保存前去重
    await db.update(
      "settings",
      {"value": jsonEncode(uniqueList)},
      where: "key='categories'",
    );
  }

  Future<void> saveLocations(List<String> list) async {
    final db = await database;
    final uniqueList = _deduplicateList(list); // 保存前去重
    await db.update(
      "settings",
      {"value": jsonEncode(uniqueList)},
      where: "key='locations'",
    );
  }

  // ----------------------------- 资产 CRUD -----------------------------
  Future<List<Asset>> getAllAssets() async {
    final db = await database;
    final maps = await db.query(
      "assets",
      where: "is_deleted = 0",
      orderBy: "updated_at DESC",
    );
    return maps.map((e) => Asset.fromMap(e)).toList();
  }

  Future<Asset?> getAssetById(String id) async {
    final db = await database;
    final maps = await db.query(
      "assets",
      where: "id = ? AND is_deleted = 0",
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Asset.fromMap(maps.first);
  }

  Future<int> insertAsset(Asset asset) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert("assets", {
      ...asset.toMap(),
      "created_at": now,
      "updated_at": now,
    });
  }

  Future<int> updateAsset(Asset asset) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      "assets",
      {
        "name": asset.name,
        "category": asset.category,
        "price": asset.price,
        "purchase_date": asset.purchaseDate.toIso8601String(),
        "location": asset.location,
        "notes": asset.notes,
        "image_url": asset.imageUrl,
        "icon_name": asset.iconName,
        "updated_at": now,
        "version": asset.version + 1,  // 版本号+1
      },
      where: "id = ?",
      whereArgs: [asset.id],
    );
  }

  Future<int> softDeleteAsset(String id) async {
    final db = await database;
    return await db.update(
      "assets",
      {
        "is_deleted": 1,
        "updated_at": DateTime.now().toIso8601String(),
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> restoreAsset(String id) async {
    final db = await database;
    return await db.update(
      "assets",
      {
        "is_deleted": 0,
        "updated_at": DateTime.now().toIso8601String(),
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ----------------------------- 资产图片 CRUD -----------------------------
  Future<int> insertImage(AssetImage image) async {
    final db = await database;
    return await db.insert("asset_images", image.toMap());
  }

  Future<List<AssetImage>> getAssetImages(String assetId) async {
    final db = await database;
    final maps = await db.query(
      "asset_images",
      where: "asset_id = ?",
      whereArgs: [assetId],
      orderBy: "created_at DESC",
    );
    return maps.map((e) => AssetImage.fromMap(e)).toList();
  }

  Future<int> deleteImage(String imageId) async {
    final db = await database;
    return await db.delete(
      "asset_images",
      where: "id = ?",
      whereArgs: [imageId],
    );
  }

  Future<int> deleteAllAssetImages(String assetId) async {
    final db = await database;
    return await db.delete(
      "asset_images",
      where: "asset_id = ?",
      whereArgs: [assetId],
    );
  }

  Future<List<AssetImage>> getAllImages() async {
    final db = await database;
    final maps = await db.query(
      "asset_images",
      orderBy: "created_at DESC",
    );
    return maps.map((e) => AssetImage.fromMap(e)).toList();
  }

  Future<void> updateImageDescription(String imageId, String description) async {
    final db = await database;
    await db.update(
      "asset_images",
      {"description": description},
      where: "id = ?",
      whereArgs: [imageId],
    );
  }
}