import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Service for the Voice Doctor multilingual chatbot.
///
/// Flow:
///   On-device STT (speech_to_text) → transcript text in user's language
///   → POST /api/speech/text-chat { text, langCode }
///   → backend: Translate input → Gemini LLM → Translate answer → Sarvam TTS
///   → { answer, audioBase64 }
class VoiceChatService {
  static String get _baseUrl => AppConstants.baseApiUrl;

  /// Sends a [transcript] (already in the user's language) and the
  /// [langCode] (2-letter code, e.g. 'te') to the backend.
  ///
  /// Returns a [VoiceChatResult] with the AI answer text and TTS audio bytes.
  static Future<VoiceChatResult> sendTextMessage({
    required String transcript,
    required String langCode,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/speech/text-chat');

    print('[VoiceChat] POST $uri  lang=$langCode  text="${transcript.substring(0, transcript.length.clamp(0, 60))}…"');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': transcript,
        'langCode': langCode,
      }),
    ).timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw Exception(
        'Request timed out. Please check your internet connection and try again.',
      ),
    );

    print('[VoiceChat] Response ${response.statusCode}, len=${response.body.length}');

    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode}). Please try again.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw Exception(
        data['error'] as String? ?? 'AI processing failed. Please try again.',
      );
    }

    // Decode TTS audio
    Uint8List? audioData;
    final audioBase64 = data['audioBase64'] as String?;
    if (audioBase64 != null && audioBase64.isNotEmpty) {
      try {
        audioData = base64Decode(audioBase64);
      } catch (_) {}
    }

    return VoiceChatResult(
      answer:    data['answer']    as String? ?? '',
      audioData: audioData,
      langCode:  data['langCode']  as String? ?? langCode,
    );
  }
}

/// Result of a voice chat exchange.
class VoiceChatResult {
  final String     answer;     // AI answer in user's language
  final Uint8List? audioData;  // Sarvam TTS WAV audio (may be null if TTS failed)
  final String     langCode;   // 2-letter code (e.g. 'te')

  const VoiceChatResult({
    required this.answer,
    this.audioData,
    required this.langCode,
  });
}
