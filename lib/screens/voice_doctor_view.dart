import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/theme/app_colors.dart';
import '../services/audio_service.dart';
import '../core/localization/translation_service.dart';

/// Voice Doctor View - A voice-enabled AI interface for symptom diagnosis
/// US14: Voice input for symptom description with language selection
/// US16: Confirmation of captured input
class VoiceDoctorView extends StatefulWidget {
  final VoidCallback? onBack;

  const VoiceDoctorView({
    super.key,
    this.onBack,
  });

  @override
  State<VoiceDoctorView> createState() => _VoiceDoctorViewState();
}

class _VoiceDoctorViewState extends State<VoiceDoctorView> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcript = '';
  String _response = '';
  bool _isAnalyzing = false;
  bool _isInitialized = false;
  late AnimationController _pulseController;

  // US14: Language selection for STT
  String _selectedLocale = 'en_US';
  List<stt.LocaleName> _availableLocales = [];

  final Map<String, String> _localeOptions = {
    'en_US': 'English',
    'hi_IN': 'Hindi',
    'te_IN': 'Telugu',
    'ta_IN': 'Tamil',
    'kn_IN': 'Kannada',
    'mr_IN': 'Marathi',
    'bn_IN': 'Bengali',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('STT Error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech error: ${error.errorMsg}')),
            );
          }
        },
      );

      if (available) {
        final locales = await _speech.locales();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _availableLocales = locales;
          });
        }
      }
    } catch (e) {
      debugPrint('STT Init Error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  /// US14: Toggle listening with selected language
  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_transcript.isNotEmpty) {
        _analyzeSymptoms();
      }
    } else {
      if (!_isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
        return;
      }

      setState(() {
        _isListening = true;
        _transcript = '';
        _response = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _transcript = result.recognizedWords;
          });
        },
        localeId: _selectedLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _analyzeSymptoms() async {
    setState(() => _isAnalyzing = true);

    // Simulate AI analysis
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _response = _generateResponse(_transcript);
      });

      // US16: Voice confirmation of result
      audioService.confirmAction('success');
      audioService.speak(_response);
    }
  }

  String _generateResponse(String symptoms) {
    final lowerSymptoms = symptoms.toLowerCase();
    
    if (lowerSymptoms.contains('yellow') || lowerSymptoms.contains('पीला')) {
      return "Based on your description, this appears to be a nutrient deficiency or possible fungal infection causing yellowing leaves. Recommended: Apply nitrogen-rich fertilizer and check soil pH.";
    } else if (lowerSymptoms.contains('spot') || lowerSymptoms.contains('धब्बे')) {
      return "The spots you're describing could indicate a fungal disease like Leaf Spot. Recommended: Remove affected leaves, improve air circulation, and apply fungicide if needed.";
    } else if (lowerSymptoms.contains('wilt') || lowerSymptoms.contains('मुर्झाना')) {
      return "Wilting symptoms suggest possible root problems or water stress. Recommended: Check for root rot, ensure proper drainage, and water consistently.";
    } else {
      return "Based on your description of '$symptoms', I recommend capturing a photo for more accurate diagnosis. Common causes include pest damage, environmental stress, or nutrient imbalance.";
    }
  }

  void _clearAndRetry() {
    setState(() {
      _transcript = '';
      _response = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('voiceView.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        foregroundColor: AppColors.nature700,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // US14: Language Selection Dropdown
                _buildLanguageSelector(),

                const SizedBox(height: 30),

                // Pulsing Mic Button
                _buildMicButton(),

                const SizedBox(height: 20),

                // Status Text
                Text(
                  _isListening
                      ? context.t('voiceView.listening')
                      : (_isInitialized
                          ? context.t('voiceView.tapToSpeak')
                          : 'Initializing...'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isListening ? AppColors.nature600 : AppColors.gray600,
                  ),
                ),

                const SizedBox(height: 40),

                // Transcript Card
                if (_transcript.isNotEmpty) _buildTranscriptCard(),

                // AI Response Card
                if (_isAnalyzing)
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: CircularProgressIndicator(),
                  )
                else if (_response.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildResponseCard(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _clearAndRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ask Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nature600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// US14: Language selection dropdown
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.language, color: AppColors.nature600),
          const SizedBox(width: 12),
          Text('Language:', style: TextStyle(color: AppColors.gray600)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedLocale,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLocale = value);
                }
              },
              items: _localeOptions.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isListening ? (1.0 + 0.1 * _pulseController.value) : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isListening
                      ? [AppColors.red400, AppColors.red600]
                      : [AppColors.nature400, AppColors.nature600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppColors.red500 : AppColors.nature500)
                        .withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                size: 48,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.purple500, size: 20),
              const SizedBox(width: 8),
              Text(
                context.t('voiceView.youSaid'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _transcript,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.nature100, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.nature200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.nature500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                context.t('voiceView.aiDoctor'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.nature700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _response,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.gray700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
