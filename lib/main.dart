import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/screens/inicio_screen.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:home_widget/home_widget.dart';

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initializeApp error: $e');
  }

  if (!kIsWeb && Platform.isIOS) {
    try {
      await HomeWidget.setAppGroupId('HomeWidgetPreferences');
    } catch (e) {
      debugPrint('HomeWidget error: $e');
    }
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Schedule reminder error: $e');
  }

  final storageService = StorageService();

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await storageService.syncFromFirestore().timeout(
      const Duration(seconds: 4),
      onTimeout: () => debugPrint('Sync from Firestore timed out on startup'),
    );
  }

  final savedThemeModeStr = await storageService.getThemeMode();
  themeModeNotifier.value =
      (savedThemeModeStr == 'light') ? ThemeMode.light : ThemeMode.dark;

  final userData = await storageService.getUserData();
  final dailyGoal = await storageService.getDailyGoal();

  final needsSetup = userData == null || dailyGoal == 0;

  if (!needsSetup) {
    try {
      await NotificationService.instance.scheduleHydrationReminder(
        minutes: userData.reminderMinutes,
      );
    } catch (e) {
      debugPrint('Schedule reminder error: $e');
    }
  }

  runApp(TomateloApp(showSetupScreen: needsSetup));
}

class TomateloApp extends StatelessWidget {
  final bool showSetupScreen;

  const TomateloApp({super.key, required this.showSetupScreen});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    Widget initialScreen;
    if (currentUser == null) {
      initialScreen = const InicioScreen();
    } else if (showSetupScreen) {
      initialScreen = const SetupScreen();
    } else {
      initialScreen = const HomeScreen();
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Tomatelo',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: initialScreen,
        );
      },
    );
  }
}
