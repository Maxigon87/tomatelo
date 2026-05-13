import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tomatelo/models/user_data.dart';

class StorageService {
  static const String _weightKey = 'weight';
  static const String _heightKey = 'height';
  static const String _reminderMinutesKey = 'reminderMinutes';
  static const String _dailyGoalKey = 'dailyGoal';
  static const String _glassesTodayKey = 'glassesToday';
  static const String _glassesYesterdayKey = 'glassesYesterday';
  static const String _lastDrinkAtKey = 'lastDrinkAt';
  static const String _lastResetKey = 'lastReset';
  static const String _weeklyDataKey = 'weeklyData';
  static const String _nutritionTodayKey = 'nutritionToday';
  static const String _nutritionGoalsKey = 'nutritionGoals';
  static const String _nutritionYesterdayKey = 'nutritionYesterday';
  static const String _nutritionWeeklyKey = 'nutritionWeekly';


  Future<void> saveNutritionToday(Map<String, int> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionTodayKey, jsonEncode(habits));
  }

  Future<Map<String, int>> getNutritionToday() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeNutritionMap(prefs.getString(_nutritionTodayKey));
  }

  Future<void> saveNutritionGoals(Map<String, int> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionGoalsKey, jsonEncode(goals));
  }

  Future<Map<String, int>> getNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeNutritionMap(prefs.getString(_nutritionGoalsKey));
  }

  Future<void> saveNutritionYesterday(Map<String, int> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionYesterdayKey, jsonEncode(habits));
  }

  Future<Map<String, int>> getNutritionYesterday() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeNutritionMap(prefs.getString(_nutritionYesterdayKey));
  }

  Future<void> saveNutritionWeeklyData(List<int> weeklyData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _nutritionWeeklyKey,
      weeklyData.map((e) => e.toString()).toList(),
    );
  }

  Future<List<int>> getNutritionWeeklyData() async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyData = prefs.getStringList(_nutritionWeeklyKey);
    if (weeklyData != null) {
      return weeklyData.map((e) => int.tryParse(e) ?? 0).toList();
    }
    return List.filled(7, 0);
  }

  Map<String, int> _decodeNutritionMap(String? value) {
    if (value == null || value.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }

    return decoded.map((key, value) {
      final parsed = value is int ? value : int.tryParse(value.toString()) ?? 0;
      return MapEntry(key, parsed);
    });
  }

  Future<void> saveWeeklyData(List<int> weeklyData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _weeklyDataKey,
      weeklyData.map((e) => e.toString()).toList(),
    );
  }

  Future<List<int>> getWeeklyData() async {
    final prefs = await SharedPreferences.getInstance();
    final weeklyData = prefs.getStringList(_weeklyDataKey);
    if (weeklyData != null) {
      return weeklyData.map((e) => int.parse(e)).toList();
    }
    return List.filled(7, 0);
  }

  Future<void> saveUserData(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weightKey, userData.weight);
    await prefs.setDouble(_heightKey, userData.height);
    await prefs.setInt(_reminderMinutesKey, userData.reminderMinutes);
  }

  Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final weight = prefs.getDouble(_weightKey);
    final height = prefs.getDouble(_heightKey);

    if (weight != null && height != null) {
      return UserData(
        weight: weight,
        height: height,
        reminderMinutes: prefs.getInt(_reminderMinutesKey) ?? 60,
      );
    }
    return null;
  }

  Future<void> saveDailyGoal(int dailyGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, dailyGoal);
  }

  Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 0;
  }

  Future<void> saveReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderMinutesKey, minutes);
  }

  Future<int> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderMinutesKey) ?? 60;
  }

  Future<void> saveGlassesToday(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_glassesTodayKey, glasses);
  }

  Future<int> getGlassesToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_glassesTodayKey) ?? 0;
  }

  Future<void> saveGlassesYesterday(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_glassesYesterdayKey, glasses);
  }

  Future<int> getGlassesYesterday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_glassesYesterdayKey) ?? 0;
  }

  Future<void> saveLastDrinkAt(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDrinkAtKey, date.toIso8601String());
  }

  Future<DateTime?> getLastDrinkAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastDrinkAtKey);
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> clearLastDrinkAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastDrinkAtKey);
  }

  Future<void> saveLastReset(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetKey, date.toIso8601String());
  }

  Future<DateTime?> getLastReset() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastResetKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }
}
