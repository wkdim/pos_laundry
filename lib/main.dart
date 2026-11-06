import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'package:provider/provider.dart';

import 'core/database/database_helper.dart';
import 'core/services/sync_service.dart';
import 'core/utils/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-specific configurations
  await _initializePlatform();

  // Initialize database
  await DatabaseHelper.instance.database;

  // Start background sync service (offline/online handling)
  SyncService.instance.start();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: LaundryPOSApp(),
    ),
  );
}

/// Initialize platform-specific settings (Windows/Linux desktop)
Future<void> _initializePlatform() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize SQLite FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Configure window properties
    await _configureWindow();
  }
}

/// Configure window size and constraints for desktop platforms
Future<void> _configureWindow() async {
  try {
    final window = await window_size.getWindowInfo();
    final screen = window.screen;

    if (screen != null) {
      // Window size constraints
      const double minWidth = 1200.0;
      const double minHeight = 900.0;
      const double defaultWidth = 1280.0;
      const double defaultHeight = 720.0;

      // Calculate maximum size (100% of screen)
      final maxWidth = screen.visibleFrame.width;
      final maxHeight = screen.visibleFrame.height;

      // Set window constraints
      window_size.setWindowMinSize(const Size(minWidth, minHeight));
      window_size.setWindowMaxSize(Size(maxWidth, maxHeight));

      // Set initial window size (centered on screen)
      final initialWidth = defaultWidth.clamp(minWidth, maxWidth);
      final initialHeight = defaultHeight.clamp(minHeight, maxHeight);

      window_size.setWindowFrame(
        Rect.fromCenter(
          center: screen.visibleFrame.center,
          width: initialWidth,
          height: initialHeight,
        ),
      );

      // Set window title (include platform label for desktop)
      final windowTitle = Platform.isWindows
          ? 'Laundry POS Pro (Windows)'
          : 'Laundry POS Pro (Desktop)';
      window_size.setWindowTitle(windowTitle);
    }
  } catch (e) {
    debugPrint('Error configuring window: $e');
  }
}

class LaundryPOSApp extends StatelessWidget {
  const LaundryPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    // platform-aware title (used for mobile & desktop window/title bar)
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;
    final bool isWindowsPlatform =
        defaultTargetPlatform == TargetPlatform.windows;
    // final platformLabel = isMobilePlatform
    //     ? 'Mobile App'
    //     : isWindowsPlatform
    //     ? 'Windows App'
    //     : defaultTargetPlatform.toString().split('.').last;
    final appTitle = 'Laundry POS Pro';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          home: SplashScreen(),
        );
      },
    );
  }
}
