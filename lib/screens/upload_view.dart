import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// Upload View — Premium dark theme with single image scan effect.
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

class _UploadViewState extends State<UploadView> with SingleTickerProviderStateMixin {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  late AnimationController _scanController;

  static const Color _bgColor = Color(0xFF0F1A2E);
  static const Color _cardBorderColor = Color(0xFF1F4D45); // Tealy border
  static const Color _iconBgColor = Color(0xFF1F3D3C);
  static const Color _iconColor = Color(0xFF27BA72);

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    if (_isLoading) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
        audioService.confirmAction('select');
      }
    } catch (e) {
      debugPrint('Image selection error: $e');
    }
  }

  void _removeImage() {
    if (_isLoading) return;
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
    audioService.confirmAction('delete');
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isLoading = true);
    audioService.confirmAction('success');
    _scanController.repeat(reverse: true);

    widget.onImagesSelected([_selectedImage!.path]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image sent for analysis'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      
      // Stop animation matching typical transition time since parent handles state
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _scanController.stop();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white70),
          onPressed: widget.onBack,
        ),
        title: Text(
          context.t('uploadView.title'), // "Upload Images" usually
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsiveMaxWidth(context)),
                    child: GestureDetector(
                      onTap: _selectedImage == null ? _selectImage : null,
                      child: _selectedImage == null
                          ? _buildEmptyState()
                          : _buildImagePreview(context),
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
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _cardBorderColor,
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
              decoration: const BoxDecoration(
                color: _iconBgColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.imagePlus,
                size: 34,
                color: _iconColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tap to select images',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Select one or more crop leaf images for analysis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Original captured image
            Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
            ),
            
            // Scanner Animation Overlay
            if (_isLoading)
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return Positioned(
                    top: _scanController.value * 400 - 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _iconColor.withOpacity(0.0),
                            _iconColor.withOpacity(0.2),
                            _iconColor.withOpacity(0.85),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            color: _iconColor,
                            boxShadow: [
                              BoxShadow(
                                color: _iconColor,
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Remove button (hidden when scanning map)
            if (!_isLoading)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
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
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _selectImage,
                icon: const Icon(LucideIcons.imagePlus, size: 20),
                label: Text(
                  context.t('uploadView.addMore'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  foregroundColor: _iconColor,
                  side: const BorderSide(color: _cardBorderColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedImage == null || _isLoading ? null : _uploadImage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Icon(LucideIcons.scan, size: 18),
                  label: Text(
                    _selectedImage == null 
                        ? context.t('uploadView.selectImages')
                        : context.t('uploadView.analyze'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF233042),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: const Color(0xFF1F2B39),
                    disabledForegroundColor: Colors.white.withOpacity(0.3),
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
