import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/screens/inicio_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb && Platform.isIOS) {
    await HomeWidget.setAppGroupId('HomeWidgetPreferences');
  }
  await NotificationService.instance.initialize();
  final storageService = StorageService();

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await storageService.syncFromFirestore().timeout(
      const Duration(seconds: 4),
      onTimeout: () => debugPrint('Sync from Firestore timed out on startup'),
    );
  }

  final userData = await storageService.getUserData();
  final dailyGoal = await storageService.getDailyGoal();

  final needsSetup = userData == null || dailyGoal == 0;

  if (!needsSetup) {
    await NotificationService.instance.scheduleHydrationReminder(
      minutes: userData!.reminderMinutes,
    );
  }

  runApp(TomateloApp(showSetupScreen: needsSetup));
}

class TomateloApp extends StatelessWidget {
  final bool showSetupScreen;

  const TomateloApp({super.key, required this.showSetupScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomatelo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: showSetupScreen ? const InicioScreen() : const HomeScreen(),
    );
  }
}
