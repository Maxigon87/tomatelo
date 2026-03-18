import 'package:flutter/material.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/screens/inicio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  final storageService = StorageService();
  final userData = await storageService.getUserData();

  if (userData != null) {
    await NotificationService.instance.scheduleHydrationReminder(
      minutes: userData.reminderMinutes,
    );
  }

  runApp(TomateloApp(showSetupScreen: userData == null));
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
      home: showSetupScreen ? const SetupScreen() : const InicioScreen(),
    );
  }
}
