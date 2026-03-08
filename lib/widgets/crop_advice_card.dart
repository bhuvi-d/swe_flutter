import 'dart:convert';
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
import '../services/region_service.dart';
import '../services/treatment_service.dart';
import '../services/explanation_service.dart';
import 'treatment_steps_widget.dart';

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
  List<String> _translatedOrganicSteps = [];
  List<String> _translatedChemicalSteps = [];
  String _targetLanguage = 'en-US';
  bool _isTranslating = false;
  String? _regionAdvice;
  String? _translatedRegionAdvice;
  Map<String, dynamic>? _structuredTreatments;
  bool _showOrganic = true; // Controls the Organic/Chemical tab switcher
  bool _showHeatmapOverlay = false; // Controls heatmap display in report

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
      _translatedOrganicSteps = List.from(widget.result.organicSteps);
      _translatedChemicalSteps = List.from(widget.result.chemicalSteps);
    } else {
      _translatedSteps = await _translateList(widget.result.treatmentSteps);
      _translatedOrganicSteps = await _translateList(widget.result.organicSteps);
      _translatedChemicalSteps = await _translateList(widget.result.chemicalSteps);
    }

    // Fetch Current Region for localized advice and dosage
    final region = await preferencesService.getRegion() ?? 'Tamil Nadu';
    _regionAdvice = await RegionService.getRegionAdvice(region, widget.result.disease);
    
    if (_regionAdvice != null && !_targetLanguage.startsWith('en')) {
      _translatedRegionAdvice = await TranslationService.translate(_regionAdvice!, _targetLanguage);
    }

    // Fetch Structured Dosage Treatments
    _structuredTreatments = await TreatmentService.getTreatment(
      widget.result.disease,
      region: region,
    );

    if (mounted) {
      setState(() => _isTranslating = false);
    }
  }

  Future<List<String>> _translateList(List<String> list) async {
    final List<String> translated = [];
    for (final item in list) {
      final t = await TranslationService.translate(item, _targetLanguage);
      translated.add(t);
    }
    return translated;
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

                  // Heatmap Viewer (US20)
                  if (widget.result.heatmapBase64 != null) ...[
                    _buildSectionTitle(Icons.layers, 'Affected Areas', Colors.redAccent),
                    _buildHeatmapViewer(),
                    const SizedBox(height: 24),
                  ],

                  // Top Predictions (US18)
                  if (widget.result.topPredictions.isNotEmpty) ...[
                    _buildSectionTitle(Icons.bar_chart, 'Alternative Predictions', const Color(0xFF818CF8)),
                    _buildTopPredictionsSection(),
                    const SizedBox(height: 24),
                  ],

                   const SizedBox(height: 24),
 
                   // Simple Explanation (US23)
                   _buildSectionTitle(LucideIcons.messageCircle, 'Simple Explanation', Colors.orangeAccent),
                   _buildGlassInfoCard(
                     ExplanationService.getSimpleExplanation(widget.result.disease),
                     icon: LucideIcons.messageCircle,
                     iconColor: Colors.orangeAccent,
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

                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Treatment Tabs (Organic vs Chemical)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showOrganic = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _showOrganic ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: _showOrganic ? Border.all(color: const Color(0xFF10B981).withOpacity(0.5)) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.eco, size: 18, color: _showOrganic ? const Color(0xFF10B981) : Colors.white54),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Organic',
                                    style: TextStyle(
                                      color: _showOrganic ? const Color(0xFF10B981) : Colors.white54,
                                      fontWeight: _showOrganic ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showOrganic = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_showOrganic ? Colors.orangeAccent.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: !_showOrganic ? Border.all(color: Colors.orangeAccent.withOpacity(0.5)) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.science, size: 18, color: !_showOrganic ? Colors.orangeAccent : Colors.white54),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chemical',
                                    style: TextStyle(
                                      color: !_showOrganic ? Colors.orangeAccent : Colors.white54,
                                      fontWeight: !_showOrganic ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Active Treatment Content
                  if (_showOrganic)
                    _buildStepsList(
                      _translatedOrganicSteps.isEmpty ? widget.result.organicSteps : _translatedOrganicSteps,
                      type: 'organic',
                    )
                  else
                    _buildStepsList(
                      _translatedChemicalSteps.isEmpty ? widget.result.chemicalSteps : _translatedChemicalSteps,
                      type: 'chemical',
                    ),

                  const SizedBox(height: 24),

                  // US30: Recovery Timeline Section
                  if (widget.result.recoveryTimeline.isNotEmpty) ...[
                    _buildSectionTitle(Icons.timeline, 'Recovery Timeline', const Color(0xFF38BDF8)),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          _buildTimelineRow(
                            'Initial Improvement',
                            '${widget.result.recoveryTimeline['initialDays'] ?? '3-5'} days',
                            Icons.trending_up,
                            const Color(0xFF38BDF8),
                          ),
                          const SizedBox(height: 12),
                          _buildTimelineRow(
                            'Full Recovery',
                            '${widget.result.recoveryTimeline['fullRecoveryDays'] ?? '14-21'} days',
                            Icons.favorite,
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 12),
                          _buildTimelineRow(
                            'Monitoring Period',
                            '${widget.result.recoveryTimeline['monitoringDays'] ?? '30'} days',
                            Icons.visibility,
                            const Color(0xFF818CF8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // US31: Prevention Checklist Section
                  if (widget.result.preventionChecklist.isNotEmpty) ...[
                    _buildSectionTitle(Icons.shield_outlined, 'Prevention Tips', const Color(0xFF22C55E)),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: widget.result.preventionChecklist.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final tip = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: idx < widget.result.preventionChecklist.length - 1
                                  ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF22C55E).withOpacity(0.15),
                                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4)),
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: Color(0xFF22C55E)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Regional Advice Section
                  if (_regionAdvice != null) ...[
                    _buildSectionTitle(Icons.map_outlined, 'Regional Advice', Colors.cyanAccent),
                    GestureDetector(
                      onTap: () {
                        TTSService.speakText(_translatedRegionAdvice ?? _regionAdvice!, _targetLanguage);
                      },
                      child: _buildGlassInfoCard(
                        _translatedRegionAdvice ?? _regionAdvice!,
                        icon: Icons.info_outline,
                        iconColor: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

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

    return TreatmentStepsWidget(
      steps: steps,
      themeColor: const Color(0xFF10B981),
    );
  }

  Widget _buildStepsList(List<String> steps, {String type = 'organic'}) {
    final structuredList = _structuredTreatments != null ? _structuredTreatments![type] as List? : null;

    if (steps.isEmpty && (structuredList == null || structuredList.isEmpty)) {
      return _buildGlassInfoCard('No steps available.', icon: Icons.info_outline, iconColor: Colors.blueAccent);
    }

    return Column(
      children: [
        if (structuredList != null && structuredList.isNotEmpty)
          ...structuredList.map((item) {
            final name = item['name'] as String;
            final dosage = item['dosage'] as String;
            final frequency = item['frequency'] as String;
            
            return _buildDosageCard(name, dosage, frequency);
          }).toList(),
        
        ...List.generate(steps.length, (index) {
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
                    backgroundColor: const Color(0xFF10B981),
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
      ],
    );
  }

  Widget _buildDosageCard(String name, String dosage, String frequency) {
    final speechText = "Apply $name. Dosage $dosage. Repeat $frequency.";
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => TTSService.speakText(speechText, _targetLanguage),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medication, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.volume_up, color: Colors.white.withOpacity(0.5), size: 18),
                ],
              ),
              const SizedBox(height: 8),
              _buildDosageInfoRow(Icons.science_outlined, "Dosage: ", dosage),
              const SizedBox(height: 4),
              _buildDosageInfoRow(Icons.event_repeat, "Frequency: ", frequency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDosageInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent.withOpacity(0.7), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // US20: Heatmap viewer with toggle
  Widget _buildHeatmapViewer() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showHeatmapOverlay = !_showHeatmapOverlay),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_showHeatmapOverlay && widget.result.heatmapBase64 != null)
                    Image.memory(
                      base64Decode(widget.result.heatmapBase64!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    _buildImage(),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showHeatmapOverlay
                            ? Colors.redAccent.withOpacity(0.3)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showHeatmapOverlay
                              ? Colors.redAccent.withOpacity(0.5)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showHeatmapOverlay ? Icons.layers_clear : Icons.layers,
                            size: 14,
                            color: _showHeatmapOverlay ? Colors.redAccent : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showHeatmapOverlay ? 'Original' : 'Heatmap',
                            style: TextStyle(
                              color: _showHeatmapOverlay ? Colors.redAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to toggle affected area heatmap',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        ),
      ],
    );
  }

  // US18: Top predictions bar chart
  Widget _buildTopPredictionsSection() {
    final predictions = widget.result.topPredictions;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: predictions.asMap().entries.map((entry) {
          final idx = entry.key;
          final pred = entry.value;
          final conf = (pred['confidence'] as num?)?.toDouble() ?? 0.0;
          final disease = pred['disease'] as String? ?? 'Unknown';
          final isTop = idx == 0;

          return Padding(
            padding: EdgeInsets.only(bottom: idx < predictions.length - 1 ? 8 : 0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: isTop ? const Color(0xFF10B981) : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    disease,
                    style: TextStyle(
                      color: isTop ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: isTop ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: conf,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTop ? const Color(0xFF10B981) : const Color(0xFF818CF8).withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(conf * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isTop ? const Color(0xFF10B981) : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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

  Widget _buildTimelineRow(String label, String duration, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            duration,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
