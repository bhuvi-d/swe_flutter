import 'dart:math';
import '../models/analysis_result.dart';
import 'preferences_service.dart';

/// Service for simulating crop disease analysis.
/// 
/// In a real application, this would upload images to a backend model.
/// Currently, it mocks the analysis process with random results.
class CropService {
  // Mock data for simulation
  final List<String> _crops = ['Tomato', 'Potato', 'Wheat', 'Rice', 'Corn'];
  final Map<String, List<String>> _diseases = {
    'Tomato': ['Early Blight', 'Late Blight', 'Leaf Mold', 'Healthy'],
    'Potato': ['Early Blight', 'Late Blight', 'Healthy'],
    'Wheat': ['Rust', 'Leaf Spot', 'Healthy'],
    'Rice': ['Bacterial Blight', 'Blast', 'Healthy'],
    'Corn': ['Rust', 'Leaf Blight', 'Healthy'],
  };

  /// Simulates analyzing an image to detect crop diseases.
  /// 
  /// - [imagePath]: Path to the image file.
  /// 
  /// Returns an [AnalysisResult] with simulated disease data.
  /// Also saves the result to local history via [PreferencesService].
  Future<AnalysisResult> analyzeImage(String imagePath) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final crop = _crops[random.nextInt(_crops.length)];
    final diseaseList = _diseases[crop]!;
    final disease = diseaseList[random.nextInt(diseaseList.length)];
    final isHealthy = disease == 'Healthy';
    
    final result = AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      imageUrl: imagePath,
      crop: crop,
      disease: disease,
      confidence: 0.70 + (random.nextDouble() * 0.29), // 0.70 - 0.99
      severity: isHealthy ? 'None' : ['Low', 'Moderate', 'High'][random.nextInt(3)],
      cause: isHealthy 
          ? 'Plant appears to be in good health.'
          : 'Fungal infection caused by Alternaria solani, often triggered by warm, humid weather.',
      symptoms: isHealthy
          ? 'Leaves are green and vibrant. No signs of spots or wilting.'
          : 'Dark, concentric rings on older leaves, yellowing tissue, and premature leaf drop.',
      immediate: isHealthy
          ? 'Continue regular care routine.'
          : 'Remove infected leaves immediately. Improve air circulation around plants.',
      chemical: isHealthy
          ? 'None required.'
          : 'Apply fungicides containing chlorothalonil or copper. Spray every 7-10 days.',
      organic: isHealthy
          ? 'Use compost tea for preventative care.'
          : 'Spray with neem oil or baking soda solution (1 tbsp baking soda, 1 tsp oil, 1 tsp soap per gallon of water).',
      prevention: isHealthy
          ? 'Ensure proper watering and spacing.'
          : 'Rotate crops every 2-3 years. Mulch to prevent soil splash. Water at the base of the plant.',
    );

    // Save to history
    await preferencesService.saveAnalysisResult(result.toJson());

    return result;
  }
}

final cropService = CropService();
