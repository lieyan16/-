import 'package:uuid/uuid.dart';

class AssetImage {
  String id;
  String assetId;
  String filePath;
  String? thumbnailPath;
  String fileName;
  int fileSize;
  DateTime createdAt;
  String? description;

  AssetImage({
    required this.assetId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    String? id,
    this.thumbnailPath,
    this.description,
    DateTime? createdAt,
  }) :
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // 从数据库Map创建对象
  factory AssetImage.fromMap(Map<String, dynamic> map) {
    return AssetImage(
      id: map['id'] as String,
      assetId: map['asset_id'] as String,
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      fileName: map['file_name'] as String,
      fileSize: map['file_size'] as int,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'file_name': fileName,
      'file_size': fileSize,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 从文件路径快速创建
  factory AssetImage.fromFile(String assetId, String filePath, String fileName, int fileSize) {
    return AssetImage(
      assetId: assetId,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  // 复制方法
  AssetImage copyWith({
    String? id,
    String? assetId,
    String? filePath,
    String? thumbnailPath,
    String? fileName,
    int? fileSize,
    String? description,
    DateTime? createdAt,
  }) {
    return AssetImage(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AssetImage{id: $id, fileName: $fileName, fileSize: ${(fileSize / 1024).toStringAsFixed(1)}KB}';
  }
}