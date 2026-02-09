import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// Upload View - Upload multiple images from gallery for diagnosis
/// US12: Upload multiple images with thumbnail carousel
/// US16: Confirmation of captured input
class UploadView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(List<String> imagePaths) onUpload;

  const UploadView({
    super.key,
    required this.onBack,
    required this.onUpload,
  });

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, Uint8List> _imagePreviews = {};
  bool _isLoading = false;

  /// US12: Select multiple images
  Future<void> _selectImages() async {
    setState(() => _isLoading = true);

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        // Load previews for thumbnails
        for (final img in images) {
          final bytes = await img.readAsBytes();
          _imagePreviews[img.path] = bytes;
        }

        setState(() {
          _selectedImages.addAll(images);
        });

        audioService.playSound('click');
      }
    } catch (e) {
      debugPrint('Error selecting images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting images: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// US12: Remove image from selection
  void _removeImage(int index) {
    setState(() {
      final removed = _selectedImages.removeAt(index);
      _imagePreviews.remove(removed.path);
    });
    audioService.playSound('click');
  }

  /// US12 & US16: Upload and confirm
  void _uploadImages() {
    if (_selectedImages.isEmpty) return;

    final paths = _selectedImages.map((img) => img.path).toList();
    
    // US16: Success confirmation
    audioService.confirmAction('success', message: 'Images ready for analysis');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('${_selectedImages.length} images selected'),
          ],
        ),
        backgroundColor: AppColors.nature600,
      ),
    );

    widget.onUpload(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
          color: AppColors.gray700,
        ),
        title: Text(
          context.t('uploadView.title'),
          style: const TextStyle(color: AppColors.gray800),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Upload Zone
                Expanded(
                  child: GestureDetector(
                    onTap: _selectImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.nature200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedImages.isEmpty
                          ? _buildEmptyState()
                          : _buildImageCarousel(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _selectImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(context.t('uploadView.addMore')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.nature500),
                          foregroundColor: AppColors.nature600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _selectedImages.isEmpty ? null : _uploadImages,
                        icon: const Icon(Icons.upload),
                        label: Text(
                          _selectedImages.isEmpty
                              ? context.t('uploadView.selectImages')
                              : '${context.t('uploadView.analyze')} ${_selectedImages.length}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nature600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: AppColors.gray300,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isLoading)
          const CircularProgressIndicator()
        else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.nature100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: AppColors.nature500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t('uploadView.uploadTitle'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('uploadView.tapToSelect'),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppColors.blue500, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.t('uploadView.supportedFormats'),
                  style: TextStyle(color: AppColors.blue600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// US12: Thumbnail preview carousel with remove option
  Widget _buildImageCarousel() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.photo_library, color: AppColors.nature600),
              const SizedBox(width: 8),
              Text(
                '${_selectedImages.length} images selected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.nature700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                    _imagePreviews.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        
        // Image Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final img = _selectedImages[index];
              final preview = _imagePreviews[img.path];

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(12),
                      image: preview != null
                          ? DecorationImage(
                              image: MemoryImage(preview),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: preview == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 40, color: AppColors.gray400),
                                const SizedBox(height: 8),
                                Text(
                                  'Image ${index + 1}',
                                  style: TextStyle(color: AppColors.gray500),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.red500,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
