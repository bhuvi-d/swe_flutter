import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/language_provider.dart';
import '../services/consent_service.dart';
import '../services/preferences_service.dart';
import '../services/crop_service.dart';
import '../widgets/crop_advice_card.dart';
import 'landing_page.dart';
import 'consent_screen.dart';
import 'language_screen.dart';
import 'login_screen.dart';
import 'home_view.dart';
import 'camera_capture_view.dart';
import 'upload_view.dart';
import 'voice_doctor_view.dart';
import 'history_view.dart';
import 'user_profile_view.dart';
import 'settings_view.dart';
import 'audio_settings_view.dart';
import 'video_recorder_view.dart';
import 'llm_advice_view.dart';
import '../models/pending_media.dart';
import '../models/analysis_result.dart';
import '../services/offline_storage_service.dart';
import 'marketing_home_page.dart';

/// MainApp - Main application container with flow management
/// Matches React's MainAppFlow and CropDiagnosisApp components
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _appState = 'loading'; // loading, landing, consent, login, language, app, marketing
  String _currentView = 'home';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await preferencesService.init();
    await consentService.init();
    
    // US15: Attempt to sync any pending offline media
    // Fire and forget - don't block app startup
    offlineStorageService.syncAllPending().then((result) {
      if (result.success > 0) {
        debugPrint('Synced ${result.success} offline items');
      }
    });

    final hasConsent = await consentService.hasConsent();
    
    if (!mounted) return;
    
    setState(() {
      _appState = hasConsent ? 'app' : 'marketing'; // Start with marketing page
      _isOnline = true; 
    });
  }

  void _handleGuestContinue() async {
    await consentService.setGuestMode(true);
    if (!mounted) return;
    setState(() {
      _appState = 'consent';
    });
  }

  void _handleLogin() {
    setState(() {
      _appState = 'login';
    });
  }

  void _handleConsentGiven() async {
    await consentService.giveConsent();
    
    if (!mounted) return;
    
    // Check if language is selected
    final languageProvider = context.read<LanguageProvider>();
    if (!languageProvider.isLanguageSelected) {
      setState(() {
        _appState = 'language';
      });
    } else {
      setState(() {
        _appState = 'app';
      });
    }
  }

  void _handleLoginComplete() async {
    // US5: Explicitly require consent even after login
    // Don't auto-grant consent. Check if already given?
    // If we consider "Login" as "Account Creation", we should show consent.
    
    if (!mounted) return;
    
    final hasConsent = await consentService.hasConsent();
    
    if (hasConsent) {
      // Already consented (maybe previous session)
      _checkLanguageAndProceed();
    } else {
      // Send to consent screen
      setState(() {
        _appState = 'consent';
      });
    }
  }

  void _checkLanguageAndProceed() {
    final languageProvider = context.read<LanguageProvider>();
    if (!languageProvider.isLanguageSelected) {
      setState(() {
        _appState = 'language';
      });
    } else {
      setState(() {
        _appState = 'app';
      });
    }
  }

  void _handleLanguageSelect(String code) async {
    final languageProvider = context.read<LanguageProvider>();
    await languageProvider.setLanguage(code);
    if (!mounted) return;
    setState(() {
      _appState = 'app';
    });
  }

  void _navigateTo(String view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_appState) {
      case 'loading':
        return _buildLoadingScreen();
      case 'marketing':
        return MarketingHomePage(
          onLaunch: () => setState(() => _appState = 'landing'),
        );
      case 'landing':
        return LandingPage(
          onGuest: _handleGuestContinue,
          onLogin: _handleLogin,
        );
      case 'consent':
        return ConsentScreen(onConsent: _handleConsentGiven);
      case 'login':
        return LoginScreen(
          onLogin: _handleLoginComplete,
          onSkip: _handleLoginComplete,
        );
      case 'language':
        return LanguageScreen(onSelect: _handleLanguageSelect);
      case 'app':
        return _buildMainApp();
      default:
        return _buildLoadingScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  color: AppColors.nature600,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your preferences...',
                style: TextStyle(
                  color: AppColors.gray600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainApp() {
    return Scaffold(
      body: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'home':
        return HomeView(
          onNavigate: _navigateTo,
          isOnline: _isOnline,
        );


// ... (inside _buildCurrentView)

      case 'camera':
        return CameraCaptureView(
          onBack: () => _navigateTo('home'),
          onCapture: (path, {String? base64Content}) async {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
            
            try {
              // Analyze
              final result = await cropService.analyzeImage(path);
              
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              // Show Result
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: CropAdviceCard(
                      result: result,
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                ),
              );
              
              if (!mounted) return;
              _navigateTo('home');
              
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              // US15: Offline Fallback - Save to PendingMedia
              try {
                final media = PendingMedia(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  filePath: path,
                  fileType: 'image',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  base64Content: base64Content, // For web persistence
                );
                
                await offlineStorageService.savePendingMedia(media);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline: Image saved to history for later'),
                    backgroundColor: AppColors.nature600,
                  ),
                );
                _navigateTo('home');
              } catch (saveError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error analyzing and saving: $e')),
                );
              }
            }
          },
        );
      case 'upload':
        return UploadView(
          onBack: () => _navigateTo('home'),
          onUpload: (paths) async {
            if (paths.isEmpty) return;
            
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
            
            try {
              AnalysisResult? firstResult;
              int successCount = 0;

              // US12: Process multiple images
              for (int i = 0; i < paths.length; i++) {
                final path = paths[i];
                // Update loading status if we could (requires stateful builder in dialog, skipping for simplicity)
                
                final result = await cropService.analyzeImage(path);
                if (i == 0) firstResult = result;
                successCount++;
              }
              
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              // Show notification for multiple items
              if (paths.length > 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Analyzed $successCount images. Results saved to history.'),
                    backgroundColor: AppColors.nature600,
                  ),
                );
              }

              // Show Result of the first one
              if (firstResult != null) {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height * 0.9,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: CropAdviceCard(
                        result: firstResult!,
                        onClose: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                );
              }
              
              if (!mounted) return;
              _navigateTo('home');
              
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error analyzing images: $e')),
              );
            }
          },
        );
      case 'voice':
        return VoiceDoctorView(
          onBack: () => _navigateTo('home'),
        );
      case 'video':
        return VideoRecorderView(
          onBack: () => _navigateTo('home'),
          onVideoRecorded: (path) async {
            // Save as pending media
            final media = PendingMedia(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              filePath: path,
              fileType: 'video',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              durationSeconds: 15, // Mock duration
            );
            
            await offlineStorageService.savePendingMedia(media);
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video saved to gallery')),
            );
            _navigateTo('home');
          },
        );
      case 'history':
        return HistoryView(
          onBack: () => _navigateTo('home'),
        );
      case 'profile':
        return UserProfileView(
          onBack: () => _navigateTo('home'),
          onLogout: () {
            // Handle logout
            setState(() {
              _appState = 'landing';
              _currentView = 'home';
            });
          },
          onLanguageChange: () {
            setState(() {
              _appState = 'language';
            });
          },
        );
      case 'settings':
        return SettingsView(
          onBack: () => _navigateTo('home'),
          onLanguageChange: () {
            setState(() {
              _appState = 'language';
            });
          },
        );
      case 'audio-settings':
        return AudioSettingsView(
          onBack: () => _navigateTo('home'),
        );
      case 'llm-advice':
        return LlmAdviceView(
          onBack: () => _navigateTo('home'),
        );
      default:
        return HomeView(
          onNavigate: _navigateTo,
          isOnline: _isOnline,
        );
    }
  }

  Widget _buildPlaceholderView(String title, IconData icon) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateTo('home'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.nature100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 80,
                  color: AppColors.nature500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
