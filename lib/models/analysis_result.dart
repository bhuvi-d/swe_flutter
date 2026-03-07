import 'dart:convert';

/// Represents the result of a crop analysis.
/// 
/// Contains details about detected diseases, confidence level, and recommended treatments.
class AnalysisResult {
  /// Unique identifier for the analysis result.
  final String id;
  
  /// The date and time when the analysis was performed.
  final DateTime date;
  
  /// URL of the image analyzed.
  final String imageUrl;
  
  /// The name of the crop (e.g., 'Tomato', 'Potato').
  final String crop;
  
  /// The detected disease or condition (e.g., 'Late Blight').
  final String disease;
  
  /// Confidence score of the diagnosis (0.0 to 1.0).
  final double confidence;
  
  /// Severity level of the disease (e.g., 'High', 'Moderate').
  final String severity;
  
  /// The underlying cause of the disease.
  final String cause;
  
  /// Visible symptoms associated with the disease.
  final String symptoms;
  
  /// Immediate actions to take.
  final String immediate;
  
  /// Recommended chemical treatments.
  final String chemical;
  
  /// Recommended organic treatments.
  final String organic;
  
  /// Preventive measures to avoid future occurrences.
  final String prevention;

  /// Creates an [AnalysisResult] instance.
  AnalysisResult({
    required this.id,
    required this.date,
    required this.imageUrl,
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.cause,
    required this.symptoms,
    required this.immediate,
    required this.chemical,
    required this.organic,
    required this.prevention,
  });

  /// Converts the [AnalysisResult] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'cause': cause,
      'symptoms': symptoms,
      'immediate': immediate,
      'chemical': chemical,
      'organic': organic,
      'prevention': prevention,
    };
  }

  /// Creates an [AnalysisResult] instance from a JSON map.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'],
      date: DateTime.parse(json['date']),
      imageUrl: json['imageUrl'],
      crop: json['crop'],
      disease: json['disease'],
      confidence: json['confidence'].toDouble(),
      severity: json['severity'],
      cause: json['cause'] ?? '',
      symptoms: json['symptoms'] ?? '',
      immediate: json['immediate'] ?? '',
      chemical: json['chemical'] ?? '',
      organic: json['organic'] ?? '',
      prevention: json['prevention'] ?? '',
    );
  }
}
