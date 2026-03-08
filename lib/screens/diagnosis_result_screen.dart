import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/analysis_result.dart';
import '../widgets/crop_advice_card.dart';
import '../services/feedback_service.dart';
import '../services/explanation_service.dart';
import '../services/preferences_service.dart';
import '../services/tts_service.dart';
import '../widgets/treatment_steps_widget.dart';
import 'chatbot_view.dart';
import 'dart:developer' as dev;

/// Full-screen diagnosis result screen (US17-20).
///
/// Displays:
/// - Disease identification card with crop label (US17)
/// - Animated confidence score with circular progress (US18)
/// - Top-5 alternative predictions bar chart (US18)
/// - Severity badge with color-coded indicator (US19)
/// - Toggleable Grad-CAM heatmap overlay on original image (US20)
/// - "View Full Report" → opens CropAdviceCard bottom sheet
class DiagnosisResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onClose;

  const DiagnosisResultScreen({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen>
    with TickerProviderStateMixin {
  bool _showHeatmap = false;
  late AnimationController _confidenceAnimController;
  late Animation<double> _confidenceAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // US31: Prevention checklist state
  final Set<int> _checkedItems = {};

  // US32: Feedback state
  String? _feedbackRating; // 'helpful' or 'not_helpful'
  bool _showCommentBox = false;
  final TextEditingController _commentController = TextEditingController();
  bool _feedbackSubmitted = false;
  bool _feedbackSubmitting = false;
  
  // US23: Voice output state
  bool _voiceEnabled = true;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _confidenceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confidenceAnim = Tween<double>(begin: 0.0, end: widget.result.confidence)
        .animate(CurvedAnimation(
      parent: _confidenceAnimController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confidenceAnimController.forward();
    });

    _loadVoicePreference();
  }

  Future<void> _loadVoicePreference() async {
    final enabled = await preferencesService.isVoiceEnabled();
    if (mounted) {
      setState(() => _voiceEnabled = enabled);
      if (_voiceEnabled) {
        _startVoiceOverview();
      }
    }
  }

  Future<void> _startVoiceOverview() async {
    if (!_voiceEnabled) return;
    
    setState(() => _isSpeaking = true);
    final explanation = ExplanationService.formatForSpeech(widget.result);
    final lang = await preferencesService.getLanguage() ?? 'en-US';
    
    await TTSService.speakText(explanation, lang);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _toggleVoice() async {
    final newState = !_voiceEnabled;
    setState(() => _voiceEnabled = newState);
    await preferencesService.setVoiceEnabled(newState);
    if (!newState) {
      await TTSService.stop();
    } else {
      _startVoiceOverview();
    }
  }

  @override
  void dispose() {
    _confidenceAnimController.dispose();
    _fadeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _openFullReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: CropAdviceCard(
            result: widget.result,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  // ==================== SEVERITY HELPERS ====================

  Color _severityColor(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'mild':
        return const Color(0xFF0EA5E9);
      case 'healthy':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _severityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return Icons.dangerous_rounded;
      case 'moderate':
        return Icons.warning_amber_rounded;
      case 'mild':
        return Icons.info_outline_rounded;
      case 'healthy':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return const Color(0xFF22C55E);
    if (confidence >= 0.70) return const Color(0xFF10B981);
    if (confidence >= 0.55) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildImageHeader(),
            if (widget.result.confidence < 0.70)
              SliverToBoxAdapter(
                child: _buildUncertaintyBanner(),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildDiseaseIdentificationCard(),
                    const SizedBox(height: 12),
                    _buildSimpleExplanationCard(),
                    const SizedBox(height: 20),
                    _buildMetricsRow(),
                    const SizedBox(height: 24),
                    _buildMultipleDetectionsView(),
                    const SizedBox(height: 24),
                    _buildTreatmentStepsSection(),
                    const SizedBox(height: 24),
                    _buildTopPredictionsChart(),
                    const SizedBox(height: 24),
                    _buildSeverityDetailCard(),
                    const SizedBox(height: 24),
                    // US30: Recovery Timeline
                    _buildRecoveryTimeline(),
                    const SizedBox(height: 24),
                    // US31: Prevention Checklist
                    _buildPreventionChecklist(),
                    const SizedBox(height: 24),
                    // US32: Treatment Feedback
                    _buildFeedbackSection(),
                    const SizedBox(height: 28),
                    _buildFullReportButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== IMAGE HEADER WITH HEATMAP TOGGLE ====================

  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0A0F1A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Original image or heatmap overlay
            if (_showHeatmap && widget.result.heatmapBase64 != null)
              Image.memory(
                base64Decode(widget.result.heatmapBase64!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              _buildOriginalImage(),

            // Gradient overlay for text readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC0A0F1A),
                    Color(0xFF0A0F1A),
                  ],
                  stops: [0.4, 0.85, 1.0],
                ),
              ),
            ),

            // Heatmap toggle button (US20)
            if (widget.result.heatmapBase64 != null)
              Positioned(
                bottom: 70,
                right: 16,
                child: _buildHeatmapToggle(),
              ),

            // Crop label at bottom
            Positioned(
              bottom: 16,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Text(
                      widget.result.crop,
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDiseaseName(widget.result.disease),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: widget.onClose,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalImage() {
    if (kIsWeb) {
      if (widget.result.imageUrl.startsWith('blob:') ||
          widget.result.imageUrl.startsWith('data:')) {
        return Image.network(widget.result.imageUrl, fit: BoxFit.cover);
      }
    }
    if (!kIsWeb) {
      final file = File(widget.result.imageUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.eco, size: 80, color: Colors.white10),
      ),
    );
  }

  Widget _buildHeatmapToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showHeatmap = !_showHeatmap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showHeatmap
              ? const Color(0xFFEF4444).withOpacity(0.25)
              : Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showHeatmap
                ? const Color(0xFFEF4444).withOpacity(0.6)
                : Colors.white24,
          ),
          boxShadow: [
            BoxShadow(
              color: _showHeatmap
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : Colors.transparent,
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showHeatmap ? Icons.layers_clear : Icons.layers,
              color: _showHeatmap ? const Color(0xFFFCA5A5) : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
              style: TextStyle(
                color: _showHeatmap ? const Color(0xFFFCA5A5) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DISEASE IDENTIFICATION CARD (US17) ====================

  Widget _buildDiseaseIdentificationCard() {
    final isHealthy = widget.result.severityLevel.toLowerCase() == 'healthy' ||
        widget.result.disease.toLowerCase().contains('healthy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHealthy
              ? [const Color(0xFF064E3B).withOpacity(0.5), const Color(0xFF065F46).withOpacity(0.3)]
              : [const Color(0xFF7F1D1D).withOpacity(0.3), const Color(0xFF991B1B).withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHealthy
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isHealthy
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : const Color(0xFFEF4444).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : LucideIcons.bug,
              color: isHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'No Disease Detected' : 'Disease Identified',
                  style: TextStyle(
                    color: isHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDiseaseName(widget.result.disease),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Crop: ${widget.result.crop}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIMPLE EXPLANATION (US23) ====================

  Widget _buildSimpleExplanationCard() {
    final simpleExp = ExplanationService.getSimpleExplanation(widget.result.disease);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 16, color: Colors.purple.shade300),
                  const SizedBox(width: 8),
                  Text(
                    'Simple Explanation',
                    style: TextStyle(
                      color: Colors.purple.shade300,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // US23: Voice Toggle
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _toggleVoice,
                icon: Icon(
                  _voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _voiceEnabled ? const Color(0xFF10B981) : Colors.white24,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            simpleExp,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TREATMENT STEPS (US25) ====================

  Widget _buildTreatmentStepsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.1)),
      ),
      child: TreatmentStepsWidget(
        steps: widget.result.treatmentSteps,
        themeColor: const Color(0xFF10B981),
      ),
    );
  }

  // ==================== CONFIDENCE + SEVERITY METRICS (US18 + US19) ====================

  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Confidence Score (US18)
        Expanded(child: _buildConfidenceCard()),
        const SizedBox(width: 14),
        // Severity Badge (US19)
        Expanded(child: _buildSeverityBadge()),
      ],
    );
  }

  Widget _buildConfidenceCard() {
    final color = _confidenceColor(widget.result.confidence);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.radar, size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'Confidence',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _confidenceAnim,
            builder: (context, child) {
              return SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _confidenceAnim.value,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(_confidenceAnim.value * 100).toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.result.confidence >= 0.85
                  ? 'Very High'
                  : widget.result.confidence >= 0.70
                      ? 'High'
                      : widget.result.confidence >= 0.55
                          ? 'Medium'
                          : 'Low',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge() {
    final level = widget.result.severityLevel;
    final color = _severityColor(level);
    final icon = _severityIcon(level);
    final label = widget.result.severity;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined,
                  size: 14, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'Severity',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Severity icon with glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOP-5 PREDICTIONS CHART (US18) ====================

  // ==================== MULTIPLE DETECTIONS (US22) ====================

  Widget _buildMultipleDetectionsView() {
    final predictions = widget.result.topPredictions;
    if (predictions.length < 2) return const SizedBox.shrink();

    // Significant secondary diseases (e.g., confidence > 25%)
    final secondaries = predictions.skip(1).where((p) => (p['confidence'] as num? ?? 0) > 0.25).toList();

    if (secondaries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.binary, size: 18, color: Color(0xFFF472B6)),
            const SizedBox(width: 8),
            Text(
              'Co-occurring Conditions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...secondaries.map((p) => _buildSecondaryDetectionCard(p)).toList(),
      ],
    );
  }

  Widget _buildSecondaryDetectionCard(Map<String, dynamic> pred) {
    final disease = pred['disease'] as String? ?? 'Unknown Condition';
    final conf = (pred['confidence'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF472B6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF472B6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF472B6).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertCircle, color: Color(0xFFF472B6), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Possible co-infection found',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(conf * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFF472B6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPredictionsChart() {
    final predictions = widget.result.topPredictions;
    if (predictions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.barChart, size: 18, color: Color(0xFF818CF8)),
            const SizedBox(width: 8),
            const Text(
              'Top Predictions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: predictions.asMap().entries.map((entry) {
              final idx = entry.key;
              final pred = entry.value;
              final conf = (pred['confidence'] as num?)?.toDouble() ?? 0.0;
              final disease = pred['disease'] as String? ?? 'Unknown';
              final crop = pred['crop'] as String? ?? '';
              final isTop = idx == 0;

              final barColor = isTop
                  ? const Color(0xFF10B981)
                  : [
                      const Color(0xFF818CF8),
                      const Color(0xFF38BDF8),
                      const Color(0xFFFBBF24),
                      const Color(0xFFF87171),
                    ][min(idx - 1, 3)];

              return Padding(
                padding: EdgeInsets.only(bottom: idx < predictions.length - 1 ? 10 : 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: isTop ? const Color(0xFF10B981) : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease,
                            style: TextStyle(
                              color: isTop ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isTop ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (crop.isNotEmpty)
                            Text(
                              crop,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: conf,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            barColor.withOpacity(isTop ? 1.0 : 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${(conf * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isTop ? barColor : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==================== UNCERTAINTY WARNING (US21) ====================

  Widget _buildUncertaintyBanner() {
    // Task: Log low-confidence predictions for monitoring
    dev.log(
      'Low confidence prediction detected',
      name: 'CropAID.Diagnosis',
      error: {'id': widget.result.id, 'disease': widget.result.disease, 'confidence': widget.result.confidence},
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFBBF24), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uncertain Diagnosis',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI confidence is lower than usual. Please verify results.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry Capture'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openExpertConsult,
                  icon: const Icon(LucideIcons.bot, size: 18),
                  label: const Text('Expert Consult'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openExpertConsult() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatbotView(
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  // ==================== SEVERITY DETAIL CARD (US19) ====================

  Widget _buildSeverityDetailCard() {
    final level = widget.result.severityLevel;
    final color = _severityColor(level);
    final description = widget.result.severityDescription;

    if (description.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_severityIcon(level), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Severity Assessment',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECOVERY TIMELINE (US30) ====================

  Widget _buildRecoveryTimeline() {
    final timeline = widget.result.recoveryTimeline;
    if (timeline.isEmpty) return const SizedBox.shrink();

    final initialDays = timeline['initialDays'] ?? '3-5';
    final fullDays = timeline['fullRecoveryDays'] ?? '14-21';
    final monitorDays = timeline['monitoringDays'] ?? '30';

    final steps = [
      _TimelineStep('Initial\nImprovement', '$initialDays days', const Color(0xFF38BDF8), LucideIcons.sprout),
      _TimelineStep('Full\nRecovery', '$fullDays days', const Color(0xFF10B981), LucideIcons.activity),
      _TimelineStep('Monitoring\nPeriod', '$monitorDays days', const Color(0xFF818CF8), LucideIcons.eye),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.clock, size: 18, color: Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            const Text(
              'Recovery Timeline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              // Timeline bar
              Row(
                children: steps.asMap().entries.expand((entry) {
                  final idx = entry.key;
                  final step = entry.value;
                  final widgets = <Widget>[
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.color.withOpacity(0.15),
                              border: Border.all(color: step.color.withOpacity(0.5), width: 2),
                            ),
                            child: Icon(step.icon, color: step.color, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: step.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              step.duration,
                              style: TextStyle(
                                color: step.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];

                  // Add connector line between steps
                  if (idx < steps.length - 1) {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: SizedBox(
                          width: 24,
                          child: Center(
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [step.color.withOpacity(0.4), steps[idx + 1].color.withOpacity(0.4)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return widgets;
                }).toList(),
              ),
              // Description
              if (timeline['description'] != null && (timeline['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timeline['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== PREVENTION CHECKLIST (US31) ====================

  Widget _buildPreventionChecklist() {
    final checklist = widget.result.preventionChecklist;
    if (checklist.isEmpty) return const SizedBox.shrink();

    final completedCount = _checkedItems.length;
    final totalCount = checklist.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.shield, size: 18, color: Color(0xFF22C55E)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Prevention Checklist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: checklist.asMap().entries.map((entry) {
              final idx = entry.key;
              final tip = entry.value;
              final isChecked = _checkedItems.contains(idx);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _checkedItems.remove(idx);
                    } else {
                      _checkedItems.add(idx);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(idx == 0
                    ? 18
                    : idx == checklist.length - 1
                        ? 18
                        : 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: idx < checklist.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isChecked
                              ? const Color(0xFF22C55E)
                              : Colors.transparent,
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xFF22C55E)
                                : Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            color: isChecked
                                ? Colors.white.withOpacity(0.4)
                                : Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.4,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==================== TREATMENT FEEDBACK (US32) ====================

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.messageCircle, size: 18, color: Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            const Text(
              'Was this helpful?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: _feedbackSubmitted
              ? _buildFeedbackConfirmation()
              : Column(
                  children: [
                    // Thumbs up / down
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeedbackButton(
                            icon: Icons.thumb_up_rounded,
                            label: 'Helpful',
                            selected: _feedbackRating == 'helpful',
                            color: const Color(0xFF22C55E),
                            onTap: () => setState(() {
                              _feedbackRating = 'helpful';
                              _showCommentBox = true;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeedbackButton(
                            icon: Icons.thumb_down_rounded,
                            label: 'Not Helpful',
                            selected: _feedbackRating == 'not_helpful',
                            color: const Color(0xFFEF4444),
                            onTap: () => setState(() {
                              _feedbackRating = 'not_helpful';
                              _showCommentBox = true;
                            }),
                          ),
                        ),
                      ],
                    ),

                    // Comment box (appears after selecting rating)
                    if (_showCommentBox) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        maxLength: 500,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a comment (optional)...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10B981)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _feedbackSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _feedbackSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Feedback',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.white38, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white54,
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackConfirmation() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.15),
          ),
          child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thank you for your feedback!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your input helps improve treatment recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackRating == null) return;

    setState(() => _feedbackSubmitting = true);

    await FeedbackService.submitFeedback(
      diagnosisId: widget.result.id,
      rating: _feedbackRating!,
      comment: _commentController.text.trim(),
      crop: widget.result.crop,
      disease: widget.result.disease,
      severity: widget.result.severity,
    );

    if (mounted) {
      setState(() {
        _feedbackSubmitting = false;
        _feedbackSubmitted = true;
      });
    }
  }

  // ==================== FULL REPORT BUTTON ====================

  Widget _buildFullReportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _openFullReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText, size: 20),
            SizedBox(width: 10),
            Text(
              'View Full Treatment Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatDiseaseName(String raw) {
    // "Tomato___Early_blight" → "Early Blight"
    String name = raw;
    if (name.contains('___')) {
      name = name.split('___').last;
    }
    name = name.replaceAll('_', ' ');
    // Title case
    return name
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

/// Data class for timeline step visualization (US30).
class _TimelineStep {
  final String label;
  final String duration;
  final Color color;
  final IconData icon;

  _TimelineStep(this.label, this.duration, this.color, this.icon);
}
