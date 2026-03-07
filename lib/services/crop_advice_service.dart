import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

/// Service for retrieving crop advice from the backend LLM.
/// 
/// This service handles:
/// - Sending analysis data (crop, disease, confidence) to the server.
/// - Parsing the AI-generated advice (cause, symptoms, treatment).
/// - Providing mock advice when offline or if the API fails.
class CropAdviceService {
  static const String baseUrl = 'https://crop-aid-backend.onrender.com';

  /// Fetches AI-generated advice for a specific crop disease.
  /// 
  /// Parameters:
  /// - [crop]: Name of the crop.
  /// - [disease]: Detected disease name.
  /// - [severity]: Severity level of the disease.
  /// - [confidence]: Confidence score of the detection.
  /// - [apiKey]: Optional API key for authentication.
  /// 
  /// Returns an [AnalysisResult] containing the advice fields.
  /// Falls back to mock data on error.
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
          treatmentSteps: data['treatmentSteps'] != null 
              ? List<String>.from(data['treatmentSteps'] as List) 
              : [
                  data['immediate'] ?? 'Remove affected parts immediately',
                  data['chemical'] ?? 'Consult local agricultural expert',
                  data['organic'] ?? 'Use neem-based solutions',
                  data['prevention'] ?? 'Maintain proper crop hygiene'
                ],
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

  /// Generates mock advice for demonstration and offline usage.
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
      chemical: 'Fungicides containing chlorothalonil or copper-based sprays are generally effective if applied early enough. Always follow local agricultural guidelines.',
      organic: 'Regular applications of neem oil or potassium bicarbonate can help suppress the disease. Ensure the soil has good drainage and adequate nutrients.',
      prevention: 'Rotate crops annually. Use resistant varieties if available. Sterilize tools after each use to prevent spreading pathogens across the farm.',
      treatmentSteps: [
        "Remove and destroy all infected leaves immediately.",
        "Improve air circulation around plants by pruning.",
        "Apply fungicide spray every 7-10 days if symptoms persist.",
        "Monitor plants regularly for new spots and overall health.",
        "Sterilize all gardening tools after use."
      ],
    );
  }
}
