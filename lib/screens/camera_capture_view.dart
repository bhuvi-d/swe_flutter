import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../core/utils/image_quality_util.dart';
import '../services/audio_service.dart';

/// Camera Capture View - Take photos for plant diagnosis.
/// 
/// User Stories Covered:
/// - US9: Capture photos using camera.
/// - US10: Guidance on taking clear photos (Overlays & Audio).
/// - US11: Blur or darkness warnings.
/// - US16: Confirmation of captured input.
class CameraCaptureView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String imagePath, {String? base64Content}) onCapture;

  const CameraCaptureView({
    super.key,
    required this.onBack,
    required this.onCapture,
  });

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;
  bool _showGuidance = true;
  String? _qualityWarning;
  XFile? _capturedImage;
  String? _base64Image; // Store base64 for web

  @override
  void initState() {
    super.initState();
    // US10: Play guidance audio on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioService.speak('Position your plant clearly in the frame for best results.');
    });
  }

  /// US9: Captures a photo using the device camera or file picker (on Web).
  /// 
  /// performs:
  /// - Hides guidance overlay.
  /// - Captures image via `ImagePicker`.
  /// - US11: Analyzes image quality (blur/darkness check).
  /// - US16: Plays success audio or error warning.
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _qualityWarning = null;
      _showGuidance = false;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        setState(() => _isCapturing = false);
        return;
      }

      // US11: Check image quality & Prepare for Web/Offline
      final bytes = await image.readAsBytes();
      
      final quality = await ImageQualityUtil.analyzeImageFromBytes(bytes);

      if (!mounted) return;

      if (!quality.isGood) {
        setState(() {
          _isCapturing = false;
          _qualityWarning = quality.isBlurry
              ? 'Image appears blurry. Please take another photo.'
              : 'Image is too dark. Try adding more light.';
          _capturedImage = image;
        });
        // US11: Audio warning
        audioService.confirmAction('error', message: _qualityWarning);
        return;
      }

      // US16: Success confirmation
      setState(() {
        _isCapturing = false;
        _capturedImage = image;
      });
      
      audioService.confirmAction('success', message: 'Photo captured successfully!');
      
      _showSuccessAndProceed(image.path, bytes: bytes);

    } catch (e) {
      debugPrint('Error capturing photo: $e');
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// US16: Shows a success snackbar and proceeds to the next step.
  /// 
  /// Handles passing base64 content for Web support.
  void _showSuccessAndProceed(String path, {Uint8List? bytes}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Photo captured successfully!'),
          ],
        ),
        backgroundColor: AppColors.nature600,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () async {
      widget.onCapture(path, base64Content: kIsWeb && bytes != null ? Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString().split(',').last : null);
    });
  }

  /// Retries capture after a quality warning.
  void _retryCapture() {
    setState(() {
      _qualityWarning = null;
      _capturedImage = null;
    });
    _capturePhoto();
  }

  /// Proceeds with the captured image despite quality warnings.
  void _proceedAnyway() async {
    if (_capturedImage != null) {
      String? base64String;
      if (kIsWeb) {
        final bytes = await _capturedImage!.readAsBytes();
        base64String = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString().split(',').last;
      }
      widget.onCapture(_capturedImage!.path, base64Content: base64String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nature50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.nature700),
          onPressed: widget.onBack,
        ),
        title: Text(
          context.t('cameraView.title'),
          style: const TextStyle(color: AppColors.nature800),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // US10: Pre-capture guidance
              if (_showGuidance) _buildGuidanceSection(),

              // Main capture area
              Expanded(
                child: _buildCaptureArea(),
              ),

              // US11: Quality warning overlay
              if (_qualityWarning != null) _buildQualityWarning(),

              // Bottom controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  /// US10: Displays guidance tips for taking clear photos.
  Widget _buildGuidanceSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.blue600),
              const SizedBox(width: 8),
              Text(
                context.t('cameraView.tips'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(Icons.wb_sunny, 'Ensure good lighting'),
          _buildTipItem(Icons.center_focus_strong, 'Focus on affected area'),
          _buildTipItem(Icons.zoom_in, 'Get close to the plant'),
          _buildTipItem(Icons.pan_tool, 'Hold device steady'),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue500),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: AppColors.blue600)),
        ],
      ),
    );
  }

  /// Builds the main camera preview area with frame guides.
  Widget _buildCaptureArea() {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.nature300,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Frame guide corners (US10)
            ..._buildFrameGuideCorners(),
            
            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCapturing ? Icons.hourglass_empty : Icons.camera_alt,
                    size: 64,
                    color: AppColors.nature400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isCapturing 
                        ? 'Processing...' 
                        : context.t('cameraView.alignPlant'),
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the corner indicators for the camera frame guide.
  List<Widget> _buildFrameGuideCorners() {
    const cornerSize = 30.0;
    const cornerWidth = 4.0;
    const color = AppColors.nature500;

    return [
      // Top-left
      Positioned(
        top: 0, left: 0,
        child: Container(
          width: cornerSize, height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: cornerWidth),
              left: BorderSide(color: color, width: cornerWidth),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 0, right: 0,
        child: Container(
          width: cornerSize, height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: cornerWidth),
              right: BorderSide(color: color, width: cornerWidth),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: Container(
          width: cornerSize, height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: cornerWidth),
              left: BorderSide(color: color, width: cornerWidth),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: Container(
          width: cornerSize, height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: cornerWidth),
              right: BorderSide(color: color, width: cornerWidth),
            ),
          ),
        ),
      ),
    ];
  }

  /// US11: Displays quality warning with options to Retry or Use Anyway.
  Widget _buildQualityWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.amber600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _qualityWarning!,
                  style: TextStyle(color: AppColors.amber800, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retryCapture,
                  child: const Text('Retry'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _proceedAnyway,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber600,
                  ),
                  child: const Text('Use Anyway'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Main capture button
          GestureDetector(
            onTap: _isCapturing ? null : _capturePhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCapturing ? AppColors.gray300 : AppColors.nature600,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.nature600.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isCapturing
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : const Icon(Icons.camera_alt, size: 36, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            kIsWeb ? 'Tap to select photo' : 'Tap to capture',
            style: TextStyle(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
