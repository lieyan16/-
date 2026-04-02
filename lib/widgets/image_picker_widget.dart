import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/asset_photo.dart';
import '../services/image_manager.dart';

class ImagePickerWidget extends StatefulWidget {
  final String assetId;
  final List<AssetPhoto> initialImages;
  final Function(List<AssetPhoto>) onImagesChanged;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    required this.assetId,
    required this.initialImages,
    required this.onImagesChanged,
    this.maxImages = 10,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  late List<AssetPhoto> _images;
  final ImageManager _imageManager = ImageManager();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _pickImageFromGallery() async {
    if (_images.length >= widget.maxImages) {
      _showMaxImagesWarning();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final XFile? imageFile = await _imageManager.pickImageFromGallery();

      if (imageFile != null && mounted) {
        final description = await _showDescriptionDialog();
        await _saveImage(imageFile, description);
      }
    } catch (e) {
      print('选择图片失败: $e');
      if (mounted) {
        _showErrorSnackbar('选择图片失败');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_images.length >= widget.maxImages) {
      _showMaxImagesWarning();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final XFile? photoFile = await _imageManager.takePhoto();

      if (photoFile != null && mounted) {
        final description = await _showDescriptionDialog();
        await _saveImage(photoFile, description);
      }
    } catch (e) {
      print('拍照失败: $e');
      if (mounted) {
        _showErrorSnackbar('拍照失败');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    TextEditingController descriptionController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('图片描述'),
        content: TextField(
          controller: descriptionController,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '输入图片描述（可选）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('跳过'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = descriptionController.text;
              Navigator.pop(context, text.isEmpty ? null : text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage(XFile imageFile, String? description) async {
    try {
      final AssetPhoto newImage = await _imageManager.saveImage(
        imageFile,
        widget.assetId,
        description: description,
      );

      setState(() {
        _images.insert(0, newImage);
      });

      widget.onImagesChanged(_images);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片添加成功'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('保存图片失败: $e');
      if (mounted) {
        _showErrorSnackbar('保存图片失败');
      }
    }
  }

  Future<void> _removeImage(int index) async {
    final removedImage = _images[index];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除图片 "${removedImage.fileName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _imageManager.deleteImage(removedImage);

        setState(() {
          _images.removeAt(index);
        });

        widget.onImagesChanged(_images);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片已删除'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('删除图片失败: $e');
        _showErrorSnackbar('删除图片失败');
      }
    }
  }

  void _showMaxImagesWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('最多只能添加 ${widget.maxImages} 张图片'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _viewImage(int index) async {
    final image = _images[index];

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // 图片查看
            Center(
              child: Image.file(
                File(image.filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 300,
                    height: 300,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            // 关闭按钮
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // 图片信息
            if (image.description != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    image.description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_images.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          '图片附件',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final image = _images[index];
            return GestureDetector(
              onTap: () => _viewImage(index),
              onLongPress: () => _removeImage(index),
              child: Stack(
                children: [
                  // 图片缩略图
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: image.thumbnailPath != null
                          ? Image.file(
                        File(image.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // 删除按钮
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // 描述提示
                  if (image.description != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          image.description!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '共 ${_images.length} 张图片，长按可删除，点击查看大图',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          '添加图片',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('从相册选择'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        Text(
          '最多可添加 ${widget.maxImages} 张图片，当前 ${_images.length} 张',
          style: TextStyle(
            fontSize: 12,
            color: _images.length >= widget.maxImages ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGrid(),
        _buildAddButtons(),
      ],
    );
  }
}