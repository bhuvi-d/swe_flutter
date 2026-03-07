import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../services/audio_service.dart';
import '../services/chat_service.dart';
import '../core/localization/translation_service.dart';

/// Voice Doctor View — Premium dark theme with real AI and responsive layout.
///
/// US14: Voice input for symptom description with language selection.
/// US16: Confirmation of captured input.
class VoiceDoctorView extends StatefulWidget {
  final VoidCallback? onBack;

  const VoiceDoctorView({super.key, this.onBack});

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

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_transcript.isNotEmpty) _analyzeSymptoms();
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
          setState(() => _transcript = result.recognizedWords);
        },
        localeId: _selectedLocale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _analyzeSymptoms() async {
    setState(() => _isAnalyzing = true);

    try {
      // Use real AI via ChatService
      final aiResponse = await ChatService.getResponse(
        "A farmer describes the following crop symptoms: '$_transcript'. "
        "Provide a brief diagnosis and recommended treatment in 3-4 sentences."
      );
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _response = aiResponse;
        });
        audioService.confirmAction('success');
        audioService.speak(_response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _response = "I couldn't analyze that right now. Please try again or describe your symptoms differently.";
        });
      }
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
      backgroundColor: const Color(0xFF0F1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
          color: Colors.white70,
        ),
        title: Text(
          context.t('voiceView.title'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveBody(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildLanguageSelector(),
                  const SizedBox(height: 40),
                  _buildMicButton(),
                  const SizedBox(height: 20),
                  // Status text
                  Text(
                    _isListening
                        ? context.t('voiceView.listening')
                        : (_isInitialized ? context.t('voiceView.tapToSpeak') : 'Initializing...'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isListening ? const Color(0xFF10B981) : Colors.white54,
                    ),
                  ),
                  if (_isListening)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildWaveformIndicator(),
                    ),
                  const SizedBox(height: 36),
                  if (_transcript.isNotEmpty) _buildTranscriptCard(),
                  if (_isAnalyzing)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  else if (_response.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildResponseCard(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _clearAndRetry,
                        icon: const Icon(LucideIcons.refreshCcw, size: 18),
                        label: const Text('Ask Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: BorderSide(color: const Color(0xFF10B981).withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.globe, color: Color(0xFF38BDF8), size: 20),
          const SizedBox(width: 12),
          Text('Language:', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedLocale,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF1E2D45),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              iconEnabledColor: Colors.white54,
              onChanged: (value) {
                if (value != null) setState(() => _selectedLocale = value);
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
          final scale = _isListening ? (1.0 + 0.08 * _pulseController.value) : 1.0;
          final glowRadius = _isListening ? 30.0 + 15.0 * _pulseController.value : 20.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                        .withOpacity(0.35),
                    blurRadius: glowRadius,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveformIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (i) {
            final offset = (i - 3).abs() * 0.15;
            final height = 8 + 14 * ((_pulseController.value + offset) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.user, size: 16, color: Color(0xFF818CF8)),
              ),
              const SizedBox(width: 10),
              const Text(
                'You said',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _transcript,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), height: 1.5),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.brain, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                context.t('voiceView.aiDoctor'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _response,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), height: 1.6),
          ),
        ],
      ),
    );
  }
}
