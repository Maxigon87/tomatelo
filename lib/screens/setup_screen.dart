import 'package:flutter/material.dart';
import 'package:tomatelo/models/user_data.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _reminderController = TextEditingController(text: '60');
  final _storageService = StorageService();

  void _saveSetup() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text.replaceAll(',', '.'));
      final height = double.parse(_heightController.text.replaceAll(',', '.'));
      final reminderMinutes = int.parse(_reminderController.text);
      final userData = UserData(
        weight: weight,
        height: height,
        reminderMinutes: reminderMinutes,
      );
      await _storageService.saveUserData(userData);

      final dailyGoalInMl = weight * 35;
      final dailyGoalInGlasses = (dailyGoalInMl / 250).round();
      await _storageService.saveDailyGoal(dailyGoalInGlasses);
      await _storageService.saveReminderMinutes(reminderMinutes);

      await NotificationService.instance.scheduleHydrationReminder(
        minutes: reminderMinutes,
      );

      await _storageService.saveLastReset(DateTime.now());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) =>
              FadeTransition(opacity: animation, child: const HomeScreen()),
        ),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HidrataSet')),
      body: WaterBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 48,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Setea tu hidratación diaria',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu peso';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Altura (cm)',
                          prefixIcon: Icon(Icons.height_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu altura';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _reminderController,
                        decoration: const InputDecoration(
                          labelText: 'Recordatorio cada (min)',
                          helperText: 'Mínimo 15 minutos para evitar spam.',
                          prefixIcon: Icon(Icons.notifications_active_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Configura cada cuánto recordarte';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null || parsed < 15) {
                            return 'Usa un valor de 15 minutos o más';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.secondaryAqua,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryAqua.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saveSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text(
                            'Iniciar hidratación',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
