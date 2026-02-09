import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/crop_advice_service.dart';
import '../widgets/crop_advice_card.dart';
import '../models/analysis_result.dart';

/// LLM Advice View - Get AI advice for crop diseases
/// Matches React's CropAdviceDemo component
class LlmAdviceView extends StatefulWidget {
  final VoidCallback onBack;

  const LlmAdviceView({
    super.key,
    required this.onBack,
  });

  @override
  State<LlmAdviceView> createState() => _LlmAdviceViewState();
}

class _LlmAdviceViewState extends State<LlmAdviceView> {
  final _cropController = TextEditingController(text: 'Tomato');
  final _diseaseController = TextEditingController(text: 'Early Blight');
  String _severity = 'medium';
  double _confidence = 0.93;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _cropController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _getAdvice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await CropAdviceService.getCropAdvice(
        crop: _cropController.text,
        disease: _diseaseController.text,
        severity: _severity,
        confidence: _confidence,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show the advice card
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
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
              result: result,
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
          context.t('llmAdvice.title'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.nature500.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t('llmAdvice.subtitle'),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Input Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('llmAdvice.diseaseInfo'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Crop Name
                    Text(
                      context.t('llmAdvice.cropName'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cropController,
                      decoration: InputDecoration(
                        hintText: context.t('llmAdvice.cropHint'),
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.nature500, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Disease Detected
                    Text(
                      context.t('llmAdvice.diseaseDetected'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _diseaseController,
                      decoration: InputDecoration(
                        hintText: context.t('llmAdvice.diseaseHint'),
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.nature500, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Severity and Confidence row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('llmAdvice.severity'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _severity,
                                    isExpanded: true,
                                    items: ['low', 'medium', 'high'].map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(s[0].toUpperCase() + s.substring(1)),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setState(() => _severity = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('llmAdvice.confidence'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: '0.00 - 1.00',
                                  filled: true,
                                  fillColor: AppColors.gray50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.gray200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.gray200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.nature500, width: 2),
                                  ),
                                ),
                                onChanged: (v) {
                                  final val = double.tryParse(v);
                                  if (val != null && val >= 0 && val <= 1) {
                                    setState(() => _confidence = val);
                                  }
                                },
                                controller: TextEditingController(text: _confidence.toStringAsFixed(2)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Error display
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Get Advice Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getAdvice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nature500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(Icons.eco),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading
                                  ? context.t('llmAdvice.generating')
                                  : context.t('llmAdvice.getAdvice'),
                              style: const TextStyle(
                                fontSize: 16,
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

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('llmAdvice.howToUse'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('llmAdvice.instructions'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
