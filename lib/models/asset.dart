import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Asset {
  String id;
  String name;
  String? category;
  double price;
  DateTime purchaseDate;
  String? location;
  String? notes;
  String? imageUrl; // 保留原有的主图片字段
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  int version;
  String? iconName; // 新增：图标名称（Material图标名称或自定义图标ID）

  Asset({
    required this.name,
    required this.price,
    required this.purchaseDate,
    String? id,
    this.category,
    this.location,
    this.notes,
    this.imageUrl,
    this.iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    int? version,
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        version = version ?? 1;

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      price: (map['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      imageUrl: map['image_url'] as String?,
      iconName: map['icon_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
      version: (map['version'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'purchase_date': _formatDateForDb(purchaseDate),
      'location': location,
      'notes': notes,
      'image_url': imageUrl,
      'icon_name': iconName,
      'created_at': _formatDateForDb(createdAt),
      'updated_at': _formatDateForDb(updatedAt),
      'is_deleted': isDeleted ? 1 : 0,
      'version': version,
    };
  }

  String _formatDateForDb(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(date);
  }

  /// 日均成本（向下取整为最小1天持有以避免除以0）
  double get dailyCost {
    final daysOwned = DateTime.now().difference(purchaseDate).inDays;
    final effectiveDays = daysOwned > 0 ? daysOwned : 1;
    return price / effectiveDays;
  }

  /// 获取持有天数的属性
  int get daysOwned {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return days < 0 ? 0 : days;
  }

  String get daysOwnedFormatted {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return '${days < 0 ? 0 : days}天';
  }

  String get purchaseDateFormatted {
    return DateFormat('yyyy年MM月dd日').format(purchaseDate);
  }

  @override
  String toString() {
    return 'Asset{id: $id, name: $name, price: ¥$price, 持有: $daysOwnedFormatted, 日均成本: ¥${dailyCost.toStringAsFixed(2)}/天}';
  }

  // 复制方法（用于更新）
  Asset copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    DateTime? purchaseDate,
    String? location,
    String? notes,
    String? imageUrl,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    int? version,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }
}