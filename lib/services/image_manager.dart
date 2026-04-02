import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;
import '../models/asset_photo.dart';

class ImageManager {
  static final ImageManager _instance = ImageManager._internal();
  factory ImageManager() => _instance;
  ImageManager._internal();

  final ImagePicker _picker = ImagePicker();

  // 获取应用图片目录
  Future<Directory> _getImagesDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory imagesDir = Directory('${appDocDir.path}/asset_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  // 获取缩略图目录
  Future<Directory> _getThumbnailsDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory thumbsDir = Directory('${appDocDir.path}/thumbnails');

    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }

    return thumbsDir;
  }

  // 从相册选择图片
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('选择图片失败: $e');
      return null;
    }
  }

  // 拍照
  Future<XFile?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );
      return photo;
    } catch (e) {
      print('拍照失败: $e');
      return null;
    }
  }

  // 压缩图片
  Future<Uint8List> _compressImage(File file, {int maxSize = 1024}) async {
    try {
      final bytes = await file.readAsBytes();

      // 使用 Flutter 的图片解码器 - 修复这里
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      // 计算缩放比例
      double width = image.width.toDouble();
      double height = image.height.toDouble();

      if (width > maxSize || height > maxSize) {
        if (width > height) {
          height = (height * maxSize / width);
          width = maxSize.toDouble();
        } else {
          width = (width * maxSize / height);
          height = maxSize.toDouble();
        }
      }

      // 使用 Canvas 绘制调整大小后的图片
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // 绘制图片
      final paint = ui.Paint();
      final srcRect = ui.Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
      final dstRect = ui.Rect.fromLTRB(0, 0, width, height);

      canvas.drawImageRect(image, srcRect, dstRect, paint);

      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('压缩图片失败: $e');
      final bytes = await file.readAsBytes();
      return bytes;
    }
  }

  // 生成缩略图
  Future<Uint8List> _generateThumbnail(File file, {int size = 200}) async {
    try {
      final bytes = await file.readAsBytes();

      // 使用 Flutter 的图片解码器 - 修复这里
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      // 使用 Canvas 绘制缩略图
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // 计算缩放以填充正方形
      final imageRatio = image.width / image.height;
      double drawWidth, drawHeight, offsetX, offsetY;

      if (imageRatio > 1) {
        // 宽图
        drawWidth = size.toDouble();
        drawHeight = size / imageRatio;
        offsetX = 0;
        offsetY = (size - drawHeight) / 2;
      } else {
        // 高图
        drawWidth = size * imageRatio;
        drawHeight = size.toDouble();
        offsetX = (size - drawWidth) / 2;
        offsetY = 0;
      }

      // 绘制图片
      final paint = ui.Paint();
      final srcRect = ui.Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
      final dstRect = ui.Rect.fromLTRB(offsetX, offsetY, offsetX + drawWidth, offsetY + drawHeight);

      canvas.drawImageRect(image, srcRect, dstRect, paint);

      final picture = recorder.endRecording();
      final thumbnail = await picture.toImage(size, size);
      final byteData = await thumbnail.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('生成缩略图失败: $e');
      final bytes = await file.readAsBytes();
      return bytes;
    }
  }

  // 保存图片到本地
  Future<AssetPhoto> saveImage(XFile xfile, String assetId, {String? description}) async {
    try {
      final File file = File(xfile.path);
      final String originalFileName = path.basename(xfile.path);
      final int fileSize = await file.length();

      // 压缩图片
      final compressedBytes = await _compressImage(file);

      // 生成缩略图
      final thumbnailBytes = await _generateThumbnail(file);

      // 获取保存目录
      final Directory imagesDir = await _getImagesDirectory();
      final Directory thumbsDir = await _getThumbnailsDirectory();

      // 生成文件名（时间戳+随机数）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecond;
      final fileName = 'asset_${assetId}_${timestamp}_$random.png';
      final thumbName = 'thumb_${assetId}_${timestamp}_$random.png';

      // 保存原图和缩略图
      final String filePath = '${imagesDir.path}/$fileName';
      final String thumbPath = '${thumbsDir.path}/$thumbName';

      await File(filePath).writeAsBytes(compressedBytes);
      await File(thumbPath).writeAsBytes(thumbnailBytes);

      // 创建AssetPhoto对象
      return AssetPhoto(
        assetId: assetId,
        filePath: filePath,
        thumbnailPath: thumbPath,
        fileName: originalFileName,
        fileSize: compressedBytes.length,
        description: description,
      );
    } catch (e) {
      print('保存图片失败: $e');
      rethrow;
    }
  }

  // 删除图片文件
  Future<void> deleteImage(AssetPhoto assetPhoto) async {
    try {
      // 删除原图
      final File imageFile = File(assetPhoto.filePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // 删除缩略图
      if (assetPhoto.thumbnailPath != null) {
        final File thumbFile = File(assetPhoto.thumbnailPath!);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }
    } catch (e) {
      print('删除图片文件失败: $e');
    }
  }

  // 获取图片文件
  Future<File?> getImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('获取图片文件失败: $e');
      return null;
    }
  }

  // 获取图片列表（按创建时间排序）
  Future<List<AssetPhoto>> getPhotosForAsset(String assetId) async {
    // 暂时返回空列表，实际需要从数据库获取
    return [];
  }

  // 清理未使用的图片（当资产被删除时）
  Future<void> cleanUpOrphanedPhotos(List<String> validAssetIds) async {
    // 暂不实现
    print('清理未使用图片功能暂未实现');
  }
}