import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../models/analysis_result.dart';
import '../screens/chatbot_view.dart';

/// A card widget that displays detailed AI-generated crop advice.
/// 
/// Shows:
/// - Crop and detected disease information.
/// - Confidence and severity levels.
/// - Detailed sections for cause, symptoms, immediate action, solutions, and prevention.
/// - Copy-to-clipboard functionality.
class CropAdviceCard extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onClose;
  final VoidCallback? onChatbotTap;

  const CropAdviceCard({
    super.key,
    required this.result,
    required this.onClose,
    this.onChatbotTap,
  });

  @override
  State<CropAdviceCard> createState() => _CropAdviceCardState();
}

class _CropAdviceCardState extends State<CropAdviceCard> {
  bool _copied = false;

  /// Copies the advice details to the system clipboard.
  void _handleCopy() {
    final text = '''
Crop: ${widget.result.crop}
Disease: ${widget.result.disease}
Severity: ${widget.result.severity}
Confidence: ${(widget.result.confidence * 100).toStringAsFixed(0)}%

CAUSE: ${widget.result.cause}
SYMPTOMS: ${widget.result.symptoms}
IMMEDIATE TREATMENT: ${widget.result.immediate}
CHEMICAL SOLUTION: ${widget.result.chemical}
ORGANIC SOLUTION: ${widget.result.organic}
PREVENTION: ${widget.result.prevention}
''';

    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return AppColors.red600;
      case 'moderate':
      case 'medium':
        return AppColors.amber600;
      default:
        return AppColors.nature600;
    }
  }

  Color _getSeverityBgColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return AppColors.red50;
      case 'moderate':
      case 'medium':
        return AppColors.amber50;
      default:
        return AppColors.nature50;
    }
  }

  void _openChatbot() {
    final onChatbotTap = widget.onChatbotTap;
    if (onChatbotTap != null) {
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 350), () {
        onChatbotTap();
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ChatbotView(
          onClose: () => Navigator.pop(ctx),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.eco, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.result.crop,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'AI-Generated Advice',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Disease Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  widget.result.disease,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: _handleCopy,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      _copied ? Icons.check : Icons.copy,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _copied ? 'Copied!' : 'Copy',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildBadge(
                              widget.result.severity,
                              _getSeverityBgColor(widget.result.severity),
                              _getSeverityColor(widget.result.severity),
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              '${(widget.result.confidence * 100).toStringAsFixed(0)}% Confidence',
                              Colors.white.withOpacity(0.2),
                              Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _AdviceSection(
                  icon: Icons.info_outline,
                  title: 'Cause',
                  content: widget.result.cause,
                  bgColor: AppColors.blue50,
                  borderColor: AppColors.blue200,
                  iconColor: AppColors.blue600,
                ),
                _AdviceSection(
                  icon: Icons.track_changes,
                  title: 'Symptoms to Look For',
                  content: widget.result.symptoms,
                  bgColor: AppColors.purple50,
                  borderColor: AppColors.purple200,
                  iconColor: AppColors.purple600,
                ),
                _AdviceSection(
                  icon: Icons.warning_amber_rounded,
                  title: 'Immediate Action',
                  content: widget.result.immediate,
                  bgColor: AppColors.red50,
                  borderColor: AppColors.red200,
                  iconColor: AppColors.red600,
                  highlight: true,
                ),
                _AdviceSection(
                  icon: Icons.sanitizer,
                  title: 'Chemical Solution',
                  content: widget.result.chemical,
                  bgColor: AppColors.amber50,
                  borderColor: AppColors.amber200,
                  iconColor: AppColors.amber600,
                ),
                _AdviceSection(
                  icon: Icons.water_drop,
                  title: 'Organic/Natural Remedy',
                  content: widget.result.organic,
                  bgColor: AppColors.nature50,
                  borderColor: AppColors.nature200,
                  iconColor: AppColors.nature600,
                ),
                _AdviceSection(
                  icon: Icons.security,
                  title: 'Prevention Tips',
                  content: widget.result.prevention,
                  bgColor: const Color(0xFFF0FDFA), // teal-50
                  borderColor: const Color(0xFF99F6E4), // teal-200
                  iconColor: const Color(0xFF0D9488), // teal-600
                ),
                
                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amber50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.amber200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, color: AppColors.amber600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Important: This advice is AI-generated and should be used as a guide. For severe cases, please consult with a local agricultural expert.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.amber800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Chatbot section - fixed at bottom, always visible
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Need more help from experts?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _openChatbot,
                  icon: const Icon(Icons.chat),
                  label: const Text("Ask Farming Expert Chatbot"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Helper widget to display a section of advice.
class _AdviceSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final bool highlight;

  const _AdviceSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.red300 : borderColor,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
