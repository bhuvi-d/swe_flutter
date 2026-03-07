import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// A guide screen that appears before the camera to explain smart features.
/// 
/// Equivalent to the "Tutorial Overlay" in React's `EnhancedCompleteCameraCapture`.
class SmartCameraGuideView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onStart;

  const SmartCameraGuideView({
    super.key,
    required this.onBack,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient to match React's backdrop blur effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.8),
                  AppColors.nature900.withOpacity(0.9),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.nature100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.center_focus_strong,
                              color: AppColors.nature600,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('smartCameraGuide.title'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.nature900,
                                  ),
                                ),
                                Text(
                                  context.t('smartCameraGuide.subtitle'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Guide Items
                      _buildGuideItem(
                        context,
                        icon: Icons.eco,
                        iconColor: Colors.green,
                        bgColor: Colors.green.withOpacity(0.1),
                        title: context.t('smartCameraGuide.autoLeafDetection'),
                        description: context.t('smartCameraGuide.autoLeafDetectionDesc'),
                      ),
                      const SizedBox(height: 16),
                      _buildGuideItem(
                        context,
                        icon: Icons.speed,
                        iconColor: Colors.blue,
                        bgColor: Colors.blue.withOpacity(0.1),
                        title: context.t('smartCameraGuide.qualityMeter'),
                        description: context.t('smartCameraGuide.qualityMeterDesc'),
                      ),
                      const SizedBox(height: 16),
                      _buildGuideItem(
                        context,
                        icon: Icons.volume_up,
                        iconColor: Colors.purple,
                        bgColor: Colors.purple.withOpacity(0.1),
                        title: context.t('smartCameraGuide.voiceGuidance'),
                        description: context.t('smartCameraGuide.voiceGuidanceDesc'),
                      ),
                      const SizedBox(height: 16),
                      _buildGuideItem(
                        context,
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.amber,
                        bgColor: Colors.amber.withOpacity(0.1),
                        title: context.t('smartCameraGuide.qualityWarnings'),
                        description: context.t('smartCameraGuide.qualityWarningsDesc'),
                      ),
                      
                      const SizedBox(height: 32),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            audioService.playClick();
                            onStart();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.nature600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            context.t('smartCameraGuide.startSmartCamera'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onBack,
                          child: Text(
                            context.t('common.cancel'),
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor.withOpacity(0.8), // Darker version of icon color for text
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: iconColor.withOpacity(0.7),
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
}
