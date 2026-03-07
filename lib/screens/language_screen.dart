import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/language_provider.dart';
import '../core/localization/translation_service.dart';

/// Screen for selecting the application language.
/// 
/// Features:
/// - Grid of available languages (English, Telugu, Hindi).
/// - Search functionality (by English or Native name).
/// - Voice input simulation for selecting language.
/// 
/// Equivalent to React's `LanguageScreen.jsx`.
class LanguageScreen extends StatefulWidget {
  final Function(String) onSelect;

  const LanguageScreen({
    super.key,
    required this.onSelect,
  });

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isListening = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Simulates voice input detection.
  /// 
  /// In a real app, this would use `speech_to_text` package.
  void _startVoiceInput() {
    setState(() {
      _isListening = true;
    });
    // TODO: Implement speech recognition
    // For now, simulate detection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  void _stopVoiceInput() {
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final filteredLanguages = languageProvider.filterLanguages(_searchQuery);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen,
              AppColors.secondaryGreen,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              
              // Title
              Text(
                context.t('languageScreen.title'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: 0.8,
                child: Text(
                  '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Search and Voice Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Search Box
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: context.t('languageScreen.searchPlaceholder'),
                            hintStyle: const TextStyle(color: Color(0xFF999999)),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF666666),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E0E0),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Voice Button
                    GestureDetector(
                      onTap: _isListening ? _stopVoiceInput : _startVoiceInput,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _isListening ? const Color(0xFFFF4757) : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? const Color(0xFFFF4757).withOpacity(0.4)
                                  : Colors.black.withOpacity(0.15),
                                  blurRadius: _isListening ? 16 : 12,
                                  offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isListening
                              ? _buildVoiceWaves()
                              : Icon(
                                  Icons.mic,
                                  size: 24,
                                  color: AppColors.primaryGreen,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Listening indicator
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          context.t('languageScreen.listening'),
                          style: const TextStyle(
                            color: Color(0xFFFFD93D),
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Language Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: filteredLanguages.isEmpty
                      ? Center(
                          child: Opacity(
                            opacity: 0.7,
                            child: Text(
                              context.t('languageScreen.noResults'),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.8,
                          ),
                          itemCount: filteredLanguages.length,
                          itemBuilder: (context, index) {
                            final lang = filteredLanguages[index];
                            return _buildLanguageButton(lang);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(LanguageInfo lang) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelect(lang.code),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lang.nativeName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              if (lang.code != 'en') ...[
                const SizedBox(height: 4),
                Text(
                  lang.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGreen.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWaves() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: Duration(milliseconds: 800 + (index * 200)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              width: 4,
              height: 12 + (index == 1 ? 8.0 : 0.0) * value,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
