import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../services/crop_advice_service.dart';
import '../widgets/crop_advice_card.dart';

/// LLM Advice View — Premium dark theme with responsive layout.
///
/// Manual AI-powered crop diagnosis: enter crop, disease, severity, confidence.
class LlmAdviceView extends StatefulWidget {
  final VoidCallback onBack;

  const LlmAdviceView({super.key, required this.onBack});

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
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await CropAdviceService.getCropAdvice(
        crop: _cropController.text,
        disease: _diseaseController.text,
        severity: _severity,
        confidence: _confidence,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

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
      setState(() { _error = e.toString(); _isLoading = false; });
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
          context.t('llmAdvice.title'),
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
        child: SingleChildScrollView(
          child: ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Icon
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.brain, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('llmAdvice.subtitle'),
                        style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Input Form
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('llmAdvice.diseaseInfo'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Crop Name
                      _buildLabel(context.t('llmAdvice.cropName')),
                      const SizedBox(height: 8),
                      _buildTextField(_cropController, context.t('llmAdvice.cropHint'), LucideIcons.leaf),
                      const SizedBox(height: 16),

                      // Disease
                      _buildLabel(context.t('llmAdvice.diseaseDetected')),
                      const SizedBox(height: 8),
                      _buildTextField(_diseaseController, context.t('llmAdvice.diseaseHint'), LucideIcons.bug),
                      const SizedBox(height: 16),

                      // Severity & Confidence Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 400) {
                            return Row(
                              children: [
                                Expanded(child: _buildSeverityDropdown()),
                                const SizedBox(width: 14),
                                Expanded(child: _buildConfidenceField()),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildSeverityDropdown(),
                              const SizedBox(height: 14),
                              _buildConfidenceField(),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                            ],
                          ),
                        ),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getAdvice,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.sparkles, size: 20),
                          label: Text(
                            _isLoading ? context.t('llmAdvice.generating') : context.t('llmAdvice.getAdvice'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
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
                    color: const Color(0xFF38BDF8).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.info, size: 16, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 8),
                          Text(
                            context.t('llmAdvice.howToUse'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t('llmAdvice.instructions'),
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF10B981)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }

  Widget _buildSeverityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.t('llmAdvice.severity')),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _severity,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E2D45),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              iconEnabledColor: Colors.white38,
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
    );
  }

  Widget _buildConfidenceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.t('llmAdvice.confidence')),
        const SizedBox(height: 8),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '0.00 - 1.00',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixIcon: const Icon(LucideIcons.barChart, size: 18, color: Color(0xFF38BDF8)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
          ),
          onChanged: (v) {
            final val = double.tryParse(v);
            if (val != null && val >= 0 && val <= 1) setState(() => _confidence = val);
          },
          controller: TextEditingController(text: _confidence.toStringAsFixed(2)),
        ),
      ],
    );
  }
}
