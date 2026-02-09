import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'preferences_service.dart';

/// Service for managing audio feedback
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool _voiceEnabled = true;
  bool _isInitialized = false;
  String _currentLanguage = 'en-IN';

  /// Initialize audio service
  Future<void> init() async {
    if (_isInitialized) return;

    _soundEnabled = await preferencesService.isSoundEnabled();
    _voiceEnabled = await preferencesService.isVoiceEnabled();

    // Default configuration
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  /// Set TTS language
  Future<void> setLanguage(String speechCode) async {
    _currentLanguage = speechCode;
    await _tts.setLanguage(speechCode);
  }

  /// Enable/disable sound effects
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await preferencesService.setSoundEnabled(enabled);
  }

  /// Enable/disable voice feedback
  Future<void> setVoiceEnabled(bool enabled) async {
    _voiceEnabled = enabled;
    await preferencesService.setVoiceEnabled(enabled);
  }

  bool get isSoundEnabled => _soundEnabled;
  bool get isVoiceEnabled => _voiceEnabled;

  /// Speak text
  Future<void> speak(String text) async {
    if (!_voiceEnabled || text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Speak with localized guidance
  Future<void> speakGuidance(String part) async {
    // US2: Voice guidance for registration
    // In a real app, these would come from localization files
    Map<String, String> prompts = {
      'welcome': 'Welcome to Crop AId. Let\'s get you registered.',
      'phone': 'Please enter your ten digit mobile number.',
      'otp': 'Please enter the six digit code sent to your phone.',
      'name': 'What is your full name?',
      'success': 'Registration successful. Welcome to the community.',
    };
    
    final prompt = prompts[part];
    if (prompt != null) {
      await speak(prompt);
    }
  }

  /// Play sound effects
  Future<void> playSound(String type) async {
    if (!_soundEnabled) return;

    // Mapping types to placeholder sound URLs (using some generic beep sounds)
    String url = '';
    switch (type) {
      case 'success':
        url = 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3';
        break;
      case 'error':
        url = 'https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3';
        break;
      case 'click':
      default:
        url = 'https://assets.mixkit.co/active_storage/sfx/2567/2567-preview.mp3';
    }

    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  /// Confirm action with sound and message
  Future<void> confirmAction(String type, {String? message}) async {
    await playSound(type);
    if (message != null) {
      await speak(message);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _tts.stop();
    await _audioPlayer.dispose();
  }
}

final audioService = AudioService();
