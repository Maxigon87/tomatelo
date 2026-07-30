import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tomatelo/models/pet_state.dart';
import 'package:tomatelo/models/user_data.dart';
import 'package:tomatelo/screens/inicio_screen.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/widgets/hydration_pet.dart';
import 'package:tomatelo/widgets/movement_pet.dart';
import 'package:tomatelo/widgets/nutrition_pet.dart';

class ProfileScreen extends StatefulWidget {
  final PetMood hydrationMood;
  final PetMood nutritionMood;
  final PetMood movementMood;
  final int dailyGoalGlasses;
  final int movementGoalSteps;
  final UserData? userData;
  final VoidCallback onDataChanged;

  const ProfileScreen({
    super.key,
    required this.hydrationMood,
    required this.nutritionMood,
    required this.movementMood,
    required this.dailyGoalGlasses,
    required this.movementGoalSteps,
    required this.userData,
    required this.onDataChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _waterGoal;
  late int _movementGoal;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _waterGoal = widget.dailyGoalGlasses;
    _movementGoal = widget.movementGoalSteps;
    _reminderMinutes = widget.userData?.reminderMinutes ?? 60;
  }

  Future<void> _saveGoals() async {
    final storage = StorageService();
    await storage.saveDailyGoal(_waterGoal);
    await storage.saveMovementGoal(_movementGoal);
    if (widget.userData != null) {
      final updatedUser = UserData(
        weight: widget.userData!.weight,
        height: widget.userData!.height,
        reminderMinutes: _reminderMinutes,
      );
      await storage.saveUserData(updatedUser);
      await NotificationService.instance.scheduleHydrationReminder(
        minutes: _reminderMinutes,
      );
    }
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Configuración guardada correctamente! 🌟')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Perfil & Mascotas Guardianas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guardian Pets Sanctuary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.hydrationPrimary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🐾 Tus Mascotas Guardianas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Gota-Bot
                      _buildPetColumn(
                        'Gota-Bot',
                        HydrationPet(mood: widget.hydrationMood, size: 70),
                        widget.hydrationMood,
                      ),
                      // Broto
                      _buildPetColumn(
                        'Broto',
                        NutritionPet(mood: widget.nutritionMood, size: 70),
                        widget.nutritionMood,
                      ),
                      // Zorro Veloz
                      _buildPetColumn(
                        'Zorro Veloz',
                        MovementPet(mood: widget.movementMood, size: 70),
                        widget.movementMood,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Daily Goals Setup Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Ajuste de Metas Diarias',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('💧 Meta de Agua (Vasos):'),
                      Text('$_waterGoal vasos (${_waterGoal * 250} ml)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _waterGoal.toDouble().clamp(4.0, 20.0),
                    min: 4,
                    max: 20,
                    divisions: 16,
                    activeColor: AppTheme.hydrationPrimary,
                    onChanged: (val) => setState(() => _waterGoal = val.toInt()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🏃 Meta de Pasos:'),
                      Text('$_movementGoal pasos', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _movementGoal.toDouble().clamp(2000.0, 20000.0),
                    min: 2000,
                    max: 20000,
                    divisions: 18,
                    activeColor: AppTheme.movementPrimary,
                    onChanged: (val) => setState(() => _movementGoal = val.toInt()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🔔 Frecuencia Recordatorios:'),
                      Text('Cada $_reminderMinutes min', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _reminderMinutes.toDouble().clamp(30.0, 180.0),
                    min: 30,
                    max: 180,
                    divisions: 10,
                    activeColor: AppTheme.nutritionPrimary,
                    onChanged: (val) => setState(() => _reminderMinutes = val.toInt()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveGoals,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar Configuración'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.hydrationPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Account & Setup Link
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_rounded, color: AppTheme.hydrationPrimary),
                    title: Text(currentUser?.email ?? 'Usuario Tomatelo'),
                    subtitle: Text(currentUser != null ? 'Sincronizado con Firebase Cloud' : 'Modo Local'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                    title: const Text('Reconfigurar Perfil Inicial'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InicioScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetColumn(String name, Widget petWidget, PetMood mood) {
    return Column(
      children: [
        petWidget,
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: mood.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            mood.displayName,
            style: TextStyle(
              color: mood.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
