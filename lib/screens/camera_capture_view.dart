import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// Camera Capture View - Take photos for plant diagnosis with AI-powered scanning.
/// 
/// Replicated from React's EnhancedCompleteCameraCapture.
/// Features:
/// - Real-time camera preview.
/// - Simulated AI plant detection with UI feedback.
/// - Live quality status pill and score.
/// - Grid overlay and zoom controls.
/// - Post-capture preparation step.
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

class _CameraCaptureViewState extends State<CameraCaptureView> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  
  // UI States
  bool _showGrid = true;
  bool _voiceInstructions = true;
  bool _showDetailedTips = false;
  double _zoomLevel = 1.0;
  bool _isPlantDetected = false;
  int _qualityScore = 45;
  String _currentStep = 'camera'; // camera, preparation
  XFile? _capturedPhoto;
  
  // Pulse Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Simulated Detection Logic
  Timer? _detectionTimer;
  Timer? _qualityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    _initializeCamera();
    _startSimulatedAnalysis();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _detectionTimer?.cancel();
    _qualityTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      final controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      if (_voiceInstructions) {
        audioService.speak(context.t('cameraView.focusOnLeaves'));
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _startSimulatedAnalysis() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _controller != null && _controller!.value.isInitialized) {
        setState(() {
          _isPlantDetected = true;
          _qualityScore = 85;
        });
        if (_voiceInstructions) {
          audioService.playSuccess();
        }
      }
    });

    _qualityTimer?.cancel();
    _qualityTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && _isPlantDetected && !_isCapturing && _controller != null) {
        setState(() {
          _qualityScore = 75 + math.Random().nextInt(20);
        });
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      audioService.playClick();
      final photo = await _controller!.takePicture();
      
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _capturedPhoto = photo;
        _currentStep = 'preparation';
      });

      if (_voiceInstructions) {
        audioService.speak(context.t('cameraView.captureNow'));
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
      _currentStep = 'camera';
      _isPlantDetected = false;
      _qualityScore = 45;
    });
    _startSimulatedAnalysis();
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    final currentIdx = _cameras!.indexOf(_controller!.description);
    final nextIdx = (currentIdx + 1) % _cameras!.length;
    
    await _controller?.dispose();
    _controller = CameraController(_cameras![nextIdx], ResolutionPreset.high);
    await _controller?.initialize();
    if (mounted) setState(() {});
  }

  void _toggleVoice() {
    setState(() {
      _voiceInstructions = !_voiceInstructions;
    });
    audioService.speak(_voiceInstructions ? 'Voice instructions enabled' : 'Voice instructions disabled');
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 'preparation') {
      return _buildPreparationView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_isInitialized && _controller != null)
            _buildCameraPreview()
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Overlays (Header, Grid, Status)
          _buildHeader(),
          if (_showGrid) _buildGridOverlay(),
          _buildSmartFocusFrame(),
          _buildStatusPill(),
          _buildZoomControls(),

          // 3. Tips Drawer
          if (_showDetailedTips) _buildTipsDrawer(),

          // 4. Bottom Controls
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Center(
      child: Transform.scale(
        scale: scale * _zoomLevel,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderButton(
              icon: Icons.close,
              label: context.t('common.back'),
              onTap: widget.onBack,
            ),
            Row(
              children: [
                _buildHeaderIcon(
                  icon: _showGrid ? Icons.grid_3x3 : Icons.grid_off,
                  active: _showGrid,
                  onTap: () => setState(() => _showGrid = !_showGrid),
                ),
                const SizedBox(width: 8),
                _buildHeaderIcon(
                  icon: Icons.flip_camera_ios,
                  onTap: _switchCamera,
                ),
                const SizedBox(width: 8),
                _buildHeaderIcon(
                  icon: _voiceInstructions ? Icons.volume_up : Icons.volume_off,
                  active: _voiceInstructions,
                  onTap: _toggleVoice,
                ),
                const SizedBox(width: 8),
                _buildHeaderIcon(
                  icon: Icons.info_outline,
                  active: _showDetailedTips,
                  onTap: () => setState(() => _showDetailedTips = !_showDetailedTips),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon({required IconData icon, bool active = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? AppColors.nature600 : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: Container(
        child: Stack(
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox.expand()),
                Container(width: 0.5, color: Colors.white.withOpacity(0.3)),
                const Expanded(child: SizedBox.expand()),
                Container(width: 0.5, color: Colors.white.withOpacity(0.3)),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
            Column(
              children: [
                const Expanded(child: SizedBox.expand()),
                Container(height: 0.5, color: Colors.white.withOpacity(0.3)),
                const Expanded(child: SizedBox.expand()),
                Container(height: 0.5, color: Colors.white.withOpacity(0.3)),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFocusFrame() {
    final color = _isPlantDetected ? Colors.green : Colors.red;
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final opacity = _isPlantDetected ? _pulseAnimation.value : 1.0;
          return Container(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                // Corners
                _buildFrameCorner(Alignment.topLeft, color.withOpacity(opacity)),
                _buildFrameCorner(Alignment.topRight, color.withOpacity(opacity)),
                _buildFrameCorner(Alignment.bottomLeft, color.withOpacity(opacity)),
                _buildFrameCorner(Alignment.bottomRight, color.withOpacity(opacity)),
                
                // Central Border
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: color.withOpacity(_isPlantDetected ? 0.4 * opacity : 0.2),
                      width: 2,
                      style: _isPlantDetected ? BorderStyle.solid : BorderStyle.none,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                // Label
                Positioned(
                  top: -30, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isPlantDetected) const Icon(Icons.eco, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _isPlantDetected ? context.t('cameraView.plantDetected') : context.t('cameraView.aimAtPlant'),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameCorner(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? const Radius.circular(8) : Radius.zero,
            topRight: alignment == Alignment.topRight ? const Radius.circular(8) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? const Radius.circular(8) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    final hasIssues = !_isPlantDetected;
    final color = hasIssues ? Colors.amber[600]! : Colors.green[500]!;

    return Positioned(
      top: 110, left: 24, right: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasIssues ? context.t('cameraView.improveQuality') : context.t('cameraView.plantDetected'),
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hasIssues ? context.t('cameraView.alignPlant') : '${context.t('cameraView.quality')}: $_qualityScore% • ${context.t('cameraView.ready')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16, top: 0, bottom: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => setState(() => _zoomLevel = math.min(5.0, _zoomLevel + 0.5)),
              ),
              Text(
                '${_zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () => setState(() => _zoomLevel = math.max(1.0, _zoomLevel - 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsDrawer() {
    return Positioned(
      bottom: 140, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Text(context.t('cameraView.photographyTips'), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                  onPressed: () => setState(() => _showDetailedTips = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildTipItem(Icons.wb_sunny, context.t('cameraView.naturalLight')),
                _buildTipItem(Icons.pan_tool, context.t('cameraView.steadyHand')),
                _buildTipItem(Icons.zoom_out_map, context.t('cameraView.fillFrame')),
                _buildTipItem(Icons.cleaning_services, context.t('cameraView.cleanLens')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.nature400, size: 14),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 24, bottom: 48, left: 32, right: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBottomIcon(Icons.info_outline, onTap: () => setState(() => _showDetailedTips = !_showDetailedTips)),
                
                // Shutter Button
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _isPlantDetected ? Colors.green : Colors.white, width: 4),
                      color: _isPlantDetected ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Container(
                        width: 65, height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPlantDetected ? Colors.green : Colors.white,
                        ),
                        child: _isCapturing ? const CircularProgressIndicator(color: Colors.black) : null,
                      ),
                    ),
                  ),
                ),

                _buildBottomIcon(Icons.flip_camera_ios, onTap: _switchCamera),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _voiceInstructions ? context.t('cameraView.voiceGuidance') : context.t('cameraView.captureNow'),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPreparationView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(context.t('cameraView.title'), style: const TextStyle(color: AppColors.nature900, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.nature700),
          onPressed: _retakePhoto,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => widget.onCapture(_capturedPhoto!.path),
            icon: const Icon(Icons.check, color: AppColors.nature700),
            label: Text(context.t('common.save'), style: const TextStyle(color: AppColors.nature700, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Preview Image
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: kIsWeb 
                   ? Image.network(_capturedPhoto!.path, fit: BoxFit.cover) 
                   : Image.file(File(_capturedPhoto!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.t('cameraView.retake')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.nature700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.nature700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onCapture(_capturedPhoto!.path),
                    icon: const Icon(Icons.check_circle),
                    label: Text(context.t('cameraView.continue')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nature600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
