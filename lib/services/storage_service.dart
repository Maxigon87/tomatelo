import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:tomatelo/models/user_data.dart';

class StorageService {
  static const String _weightKey = 'weight';
  static const String _heightKey = 'height';
  static const String _dailyGoalKey = 'dailyGoal';
  static const String _glassesTodayKey = 'glassesToday';
  static const String _glassesYesterdayKey = 'glassesYesterday';
  static const String _lastResetKey = 'lastReset';
  static const String _weeklyDataKey = 'weeklyData';

  Future<void> saveWeeklyData(List<int> weeklyData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_weeklyDataKey, weeklyData.map((e) => e.toString()).toList());
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
  }

  Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final weight = prefs.getDouble(_weightKey);
    final height = prefs.getDouble(_heightKey);

    if (weight != null && height != null) {
      return UserData(weight: weight, height: height);
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
