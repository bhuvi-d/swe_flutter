import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/language_provider.dart';
import 'core/localization/translation_service.dart';
import 'services/preferences_service.dart';
import 'services/consent_service.dart';
import 'services/audio_service.dart';
import 'screens/main_app.dart';

// Firebase conditionally imported for platforms that support it
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (may fail on web without configuration)
  try {
    if (!kIsWeb) {
      // Only initialize on mobile for now as web requires options
      // which are not yet configured. The app will use Demo Mode on web.
      await Firebase.initializeApp();
    } else {
      debugPrint('Web: Skipping Firebase init to force Demo Mode (no options)');
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Set preferred orientations (only on mobile)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  await preferencesService.init();
  await consentService.init();
  await audioService.init();

  runApp(const CropAIdApp());
}

/// CropAId - Smart Crop Diagnosis & Farmer Support Platform
/// Flutter conversion of the React Vite web app
class CropAIdApp extends StatelessWidget {
  const CropAIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'CropAId',
            debugShowCheckedModeBanner: false,
            
            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // Localization
            locale: languageProvider.locale,
            supportedLocales: supportedLanguages.map((l) => l.locale).toList(),
            localizationsDelegates: const [
              TranslationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Main App
            home: const MainApp(),
          );
        },
      ),
    );
  }
}
