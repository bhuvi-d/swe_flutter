import 'dart:convert';
import 'package:http/http.dart' as http;

class AIPredictionService {
  static const String aiUrl = "http://localhost:8000/predict";

  static const Map<int, String> diseaseMap = {
    0: "Healthy",
    1: "Leaf Spot",
    2: "Blight",
    3: "Rust",
    4: "Powdery Mildew"
  };

  static Future<Map<String, dynamic>> predict(List<int> imageBytes) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse(aiUrl),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        imageBytes,
        filename: "leaf.jpg",
      ),
    );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    print("AI RAW RESPONSE: $responseBody");

    if (response.statusCode != 200) {
      throw Exception('Failed to get prediction from AI model: ${response.statusCode}');
    }

    final result = jsonDecode(responseBody);
    
    if (result is Map<String, dynamic>) {
      print("AI class_index: ${result['class_index']}");
      print("AI confidence: ${result['confidence']}");
    }

    return result;
  }
}
