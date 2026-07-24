import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  HealthService._privateConstructor();
  static final HealthService instance = HealthService._privateConstructor();

  final Health _health = Health();

  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.EXERCISE_TIME,
  ];

  final List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// Checks if Health Connect integration is available on the current platform.
  Future<bool> isAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      await _health.configure();
      return true;
    } catch (e) {
      debugPrint('Health Service check availability error: $e');
      return false;
    }
  }

  /// Checks if read permissions are already granted.
  Future<bool> hasPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final hasPerm = await _health.hasPermissions(_types, permissions: _permissions);
      return hasPerm ?? false;
    } catch (e) {
      debugPrint('Health Service hasPermissions error: $e');
      return false;
    }
  }

  /// Requests the necessary Health Connect permissions.
  Future<bool> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final requested = await _health.requestAuthorization(_types, permissions: _permissions);
      return requested;
    } catch (e) {
      debugPrint('Health Service requestPermissions error: $e');
      return false;
    }
  }

  /// Queries steps and exercise minutes for today (since midnight).
  Future<Map<String, int>> fetchTodayData() async {
    if (kIsWeb || !Platform.isAndroid) {
      return {'steps': 0, 'minutes': 0};
    }

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 0, 0, 0);

      final permissionsGranted = await hasPermissions();
      if (!permissionsGranted) {
        return {'steps': 0, 'minutes': 0};
      }

      int steps = 0;
      try {
        final stepsCount = await _health.getTotalStepsInInterval(midnight, now);
        steps = stepsCount ?? 0;
      } catch (e) {
        debugPrint('Error fetching steps from Health Connect: $e');
      }

      int minutes = 0;
      try {
        final healthData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.EXERCISE_TIME],
          startTime: midnight,
          endTime: now,
        );

        double totalMinutes = 0;
        for (var data in healthData) {
          if (data.type == HealthDataType.EXERCISE_TIME) {
            final numericValue = double.tryParse(data.value.toString()) ?? 0;
            if (data.unit == HealthDataUnit.MINUTE) {
              totalMinutes += numericValue;
            } else if (data.unit == HealthDataUnit.SECOND) {
              totalMinutes += numericValue / 60.0;
            } else if (data.unit == HealthDataUnit.MILLISECOND) {
              totalMinutes += numericValue / 60000.0;
            } else {
              totalMinutes += numericValue; // Default fallback
            }
          }
        }
        minutes = totalMinutes.round();
      } catch (e) {
        debugPrint('Error fetching exercise minutes from Health: $e');
      }

      return {
        'steps': steps,
        'minutes': minutes,
      };
    } catch (e) {
      debugPrint('Error in fetchTodayData: $e');
      return {'steps': 0, 'minutes': 0};
    }
  }
}
