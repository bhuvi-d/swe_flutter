import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

/// CropAdviceService - Get AI-generated crop advice
/// Integrates with backend LLM advice endpoint
class CropAdviceService {
  static const String baseUrl = 'https://crop-aid-backend.onrender.com';

  /// Get AI-generated crop advice
  static Future<AnalysisResult> getCropAdvice({
    required String crop,
    required String disease,
    required String severity,
    required double confidence,
    String? apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/llm-advice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'crop': crop,
          'disease': disease,
          'severity': severity,
          'confidence': confidence,
          if (apiKey != null) 'apiKey': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Return AnalysisResult for the CropAdviceCard
        return AnalysisResult(
          id: 'llm_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          imageUrl: '', // No image for LLM-only advice
          crop: crop,
          disease: disease,
          severity: severity,
          confidence: confidence,
          cause: data['cause'] ?? 'Unknown cause',
          symptoms: data['symptoms'] ?? 'Check plant for visible signs',
          immediate: data['immediate'] ?? 'Remove affected parts immediately',
          chemical: data['chemical'] ?? 'Consult local agricultural expert',
          organic: data['organic'] ?? 'Use neem-based solutions',
          prevention: data['prevention'] ?? 'Maintain proper crop hygiene',
        );
      } else {
        // Return mock data if API fails (for demo purposes)
        return _getMockAdvice(crop, disease, severity, confidence);
      }
    } catch (e) {
      // Return mock data if network fails (offline support)
      return _getMockAdvice(crop, disease, severity, confidence);
    }
  }

  /// Get mock advice for offline/demo use
  static AnalysisResult _getMockAdvice(
    String crop,
    String disease,
    String severity,
    double confidence,
  ) {
    return AnalysisResult(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      imageUrl: '',
      crop: crop,
      disease: disease,
      severity: severity,
      confidence: confidence,
      cause: 'This disease is typically caused by fungal pathogens that thrive in warm, humid conditions. Spores spread through wind, rain splash, and contaminated tools.',
      symptoms: 'Look for dark brown to black spots on lower leaves, yellowing around lesions, concentric rings (target-like pattern), wilting of affected leaves, and eventual defoliation.',
      immediate: 'Remove and destroy all infected leaves immediately. Do not compost them. Improve air circulation around plants. Avoid overhead watering.',
      chemical: 'Apply copper-based fungicides (Bordeaux mixture) or chlorothalonil every 7-10 days. Apply in early morning. Follow manufacturer instructions for dilution.',
      organic: 'Use baking soda spray (1 tbsp per gallon water). Apply neem oil solution weekly. Use compost tea as foliar spray. Rotate with milk spray (1:9 milk to water ratio).',
      prevention: 'Use resistant varieties, practice 3-year crop rotation, mulch around plants, stake for air circulation, water at soil level early morning, and maintain proper spacing.',
    );
  }
}
