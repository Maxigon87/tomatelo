import 'package:flutter/material.dart';
import 'package:tomatelo/models/user_data.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/screens/home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _storageService = StorageService();

  void _saveSetup() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text.replaceAll(',', '.'));
      final height = double.parse(_heightController.text.replaceAll(',', '.'));
      final userData = UserData(weight: weight, height: height);
      await _storageService.saveUserData(userData);

      final dailyGoalInMl = weight * 35;
      final dailyGoalInGlasses = (dailyGoalInMl / 250).round();
      await _storageService.saveDailyGoal(dailyGoalInGlasses);

      await _storageService.saveLastReset(DateTime.now());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomatelo - Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSetup,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
