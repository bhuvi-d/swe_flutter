import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../models/analysis_result.dart';
import '../services/preferences_service.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';

/// A sophisticated advice card matching the React application's high-end UI.
/// Replicates the 'ImageAnalysis' component with a dark, premium aesthetic.
class CropAdviceCard extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onClose;

  const CropAdviceCard({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  State<CropAdviceCard> createState() => _CropAdviceCardState();
}

class _CropAdviceCardState extends State<CropAdviceCard> {
  bool _copied = false;
  List<String> _translatedSteps = [];
  String _targetLanguage = 'en-US';
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _initializeTranslations();
  }

  Future<void> _initializeTranslations() async {
    setState(() => _isTranslating = true);
    
    _targetLanguage = await preferencesService.getLanguage() ?? 'en-US';
    
    if (_targetLanguage.startsWith('en')) {
      _translatedSteps = List.from(widget.result.treatmentSteps);
    } else {
      final List<String> translated = [];
      for (final step in widget.result.treatmentSteps) {
        final t = await TranslationService.translate(step, _targetLanguage);
        translated.add(t);
      }
      _translatedSteps = translated;
    }

    if (mounted) {
      setState(() => _isTranslating = false);
    }
  }

  void _handleCopy() {
    final text = '''
Crop: ${widget.result.crop}
Disease: ${widget.result.disease}
Severity: ${widget.result.severity}
Confidence: ${(widget.result.confidence * 100).toStringAsFixed(0)}%
Analysis: ${widget.result.cause}
''';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // React-matching dark background
      body: CustomScrollView(
        slivers: [
          // 1. Large Image Header with Gradient
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xFF0F172A),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.crop,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.result.disease,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence & Severity Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Confidence',
                          '${(widget.result.confidence * 100).toInt()}%',
                          Icons.radar,
                          color: const Color(0xFF10B981),
                          progress: widget.result.confidence,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Severity',
                          widget.result.severity,
                          Icons.error_outline,
                          color: _getSeverityColor(widget.result.severity),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // AI Insight Section (Quick Tip)
                  _buildSectionTitle(LucideIcons.sparkles, 'AI Insight', Colors.purpleAccent),
                  _buildGlassInfoCard(
                    widget.result.cause,
                    icon: Icons.lightbulb_outline,
                    iconColor: Colors.amberAccent,
                  ),

                  const SizedBox(height: 24),

                  // Symptoms Section
                  _buildSectionTitle(LucideIcons.list, 'Detected Symptoms', Colors.blueAccent),
                  _buildSymptomsTags(),

                  const SizedBox(height: 24),

                  // Treatment Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(LucideIcons.checkCircle, 'Recommended Actions', const Color(0xFF10B981)),
                      TextButton.icon(
                        onPressed: _isTranslating ? null : () {
                          TTSService.speakSteps(_translatedSteps, _targetLanguage);
                        },
                        icon: Icon(
                          _isTranslating ? Icons.hourglass_empty : Icons.volume_up, 
                          size: 20, 
                          color: const Color(0xFF10B981)
                        ),
                        label: Text(
                          _isTranslating ? 'Translating...' : 'Play Instructions',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  _buildTreatmentList(),

                  const SizedBox(height: 32),

                  // Bottom Action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleCopy,
                      icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
                      label: Text(_copied ? 'Copied to Clipboard' : 'Share Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      if (widget.result.imageUrl.startsWith('blob:') || widget.result.imageUrl.startsWith('data:')) {
        return Image.network(widget.result.imageUrl, fit: BoxFit.cover);
      }
    }
    
    final file = File(widget.result.imageUrl);
    if (!kIsWeb && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    
    // Fallback if image not found (local history item with expired temp path)
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.eco, size: 80, color: Colors.white10),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, {required Color color, double? progress}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (progress != null)
                SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInfoCard(String content, {required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Text(
        content,
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
      ),
    );
  }

  Widget _buildSymptomsTags() {
    final symptoms = widget.result.symptoms.split(',');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(s.trim(), style: const TextStyle(color: Colors.white54, fontSize: 13)),
      )).toList(),
    );
  }

  Widget _buildTreatmentList() {
    final steps = _translatedSteps.isEmpty ? widget.result.treatmentSteps : _translatedSteps;
    
    if (steps.isEmpty) {
      return _buildGlassInfoCard('No specific treatment steps available.', icon: Icons.info_outline, iconColor: Colors.blueAccent);
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final stepNumber = index + 1;
        final stepText = steps[index];

        return GestureDetector(
          onTap: () {
            TTSService.speakText(stepText, _targetLanguage);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.green,
                  child: Text(
                    "$stepNumber",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stepText,
                    style: TextStyle(
                      color: _isTranslating ? Colors.white38 : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.volume_up, size: 18, color: Colors.white24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'high':
        return Colors.redAccent;
      case 'moderate':
      case 'medium':
        return Colors.amberAccent;
      case 'low':
      case 'healthy':
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }
}
