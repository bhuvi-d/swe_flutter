import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// Upload View — Premium dark theme with responsive grid.
///
/// US12: Upload multiple images with thumbnail carousel.
/// US16: Confirmation of uploaded/selected media.
class UploadView extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final VoidCallback onBack;

  const UploadView({
    super.key,
    required this.onImagesSelected,
    required this.onBack,
  });

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];
  bool _isLoading = false;

  Future<void> _selectImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        final bytes = await Future.wait(images.map((f) => f.readAsBytes()));
        setState(() {
          _selectedImages.addAll(images);
          _imageBytes.addAll(bytes);
        });
        audioService.confirmAction('select');
      }
    } catch (e) {
      debugPrint('Image selection error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytes.removeAt(index);
    });
    audioService.confirmAction('delete');
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isLoading = true);
    audioService.confirmAction('success');

    final paths = _selectedImages.map((f) => f.path).toList();
    widget.onImagesSelected(paths);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedImages.length} image(s) sent for analysis'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBack,
          color: Colors.white70,
        ),
        title: Text(
          context.t('uploadView.title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1A2E), Color(0xFF1A2940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ResponsiveBody(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Drop Zone
                        GestureDetector(
                          onTap: _selectImages,
                          child: _selectedImages.isEmpty
                              ? _buildEmptyState()
                              : _buildImageGrid(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom Action Bar
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.2),
                    const Color(0xFF10B981).withOpacity(0.05),
                  ],
                ),
              ),
              child: const Icon(
                LucideIcons.imagePlus,
                size: 36,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap to select images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select one or more crop leaf images for analysis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    final cols = responsiveColumns(context, mobile: 2, tablet: 3, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.image, size: 18, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              '${_selectedImages.length} image(s) selected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              // Add more button
              return GestureDetector(
                onTap: _selectImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus, color: Colors.white.withOpacity(0.4), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Add More',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    image: DecorationImage(
                      image: MemoryImage(_imageBytes[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Remove button
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
                // Index badge
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsiveMaxWidth(context)),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _selectImages,
                  icon: const Icon(LucideIcons.imagePlus, size: 18),
                  label: Text(context.t('uploadView.addMore')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.4)),
                    foregroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _selectedImages.isEmpty || _isLoading ? null : _uploadImages,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.scan, size: 18),
                  label: Text(
                    _selectedImages.isEmpty
                        ? context.t('uploadView.selectImages')
                        : '${context.t('uploadView.analyze')} ${_selectedImages.length}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
