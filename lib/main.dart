import 'package:flutter/material.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  final userData = await storageService.getUserData();
  runApp(TomateloApp(showSetupScreen: userData == null));
}

class TomateloApp extends StatelessWidget {
  final bool showSetupScreen;

  const TomateloApp({super.key, required this.showSetupScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomatelo',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.red,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: showSetupScreen ? const SetupScreen() : const HomeScreen(),
    );
  }
}
