import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  DocumentReference? get _userDoc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Future<void> _syncToFirestore(String key, dynamic value) async {
    try {
      final doc = _userDoc;
      if (doc != null) {
        await doc.set({key: value}, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error syncing $key to Firestore: $e');
    }
  }

  Future<void> syncFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();

      if (data.containsKey(_weightKey)) {
        await prefs.setDouble(_weightKey, (data[_weightKey] as num).toDouble());
      }
      if (data.containsKey(_heightKey)) {
        await prefs.setDouble(_heightKey, (data[_heightKey] as num).toDouble());
      }
      if (data.containsKey(_reminderMinutesKey)) {
        await prefs.setInt(_reminderMinutesKey, data[_reminderMinutesKey] as int);
      }
      if (data.containsKey(_dailyGoalKey)) {
        await prefs.setInt(_dailyGoalKey, data[_dailyGoalKey] as int);
      }
      if (data.containsKey(_glassesTodayKey)) {
        await prefs.setInt(_glassesTodayKey, data[_glassesTodayKey] as int);
      }
      if (data.containsKey(_glassesYesterdayKey)) {
        await prefs.setInt(_glassesYesterdayKey, data[_glassesYesterdayKey] as int);
      }
      if (data.containsKey(_lastDrinkAtKey)) {
        await prefs.setString(_lastDrinkAtKey, data[_lastDrinkAtKey] as String);
      }
      if (data.containsKey(_lastResetKey)) {
        await prefs.setString(_lastResetKey, data[_lastResetKey] as String);
      }

      if (data.containsKey(_weeklyDataKey)) {
        final list = List<int>.from((data[_weeklyDataKey] as List).map((e) => e as int));
        await prefs.setStringList(_weeklyDataKey, list.map((e) => e.toString()).toList());
      }
      if (data.containsKey(_nutritionTodayKey)) {
        final map = Map<String, int>.from(data[_nutritionTodayKey] as Map);
        await prefs.setString(_nutritionTodayKey, jsonEncode(map));
      }
      if (data.containsKey(_nutritionGoalsKey)) {
        final map = Map<String, int>.from(data[_nutritionGoalsKey] as Map);
        await prefs.setString(_nutritionGoalsKey, jsonEncode(map));
      }
      if (data.containsKey(_nutritionYesterdayKey)) {
        final map = Map<String, int>.from(data[_nutritionYesterdayKey] as Map);
        await prefs.setString(_nutritionYesterdayKey, jsonEncode(map));
      }
      if (data.containsKey(_nutritionWeeklyKey)) {
        final list = List<int>.from((data[_nutritionWeeklyKey] as List).map((e) => e as int));
        await prefs.setStringList(_nutritionWeeklyKey, list.map((e) => e.toString()).toList());
      }
    } catch (e) {
      print('Error syncing from Firestore: $e');
    }
  }

  Future<void> saveNutritionToday(Map<String, int> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionTodayKey, jsonEncode(habits));
    await _syncToFirestore(_nutritionTodayKey, habits);
  }

  Future<Map<String, int>> getNutritionToday() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeNutritionMap(prefs.getString(_nutritionTodayKey));
  }

  Future<void> saveNutritionGoals(Map<String, int> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionGoalsKey, jsonEncode(goals));
    await _syncToFirestore(_nutritionGoalsKey, goals);
  }

  Future<Map<String, int>> getNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeNutritionMap(prefs.getString(_nutritionGoalsKey));
  }

  Future<void> saveNutritionYesterday(Map<String, int> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nutritionYesterdayKey, jsonEncode(habits));
    await _syncToFirestore(_nutritionYesterdayKey, habits);
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
    await _syncToFirestore(_nutritionWeeklyKey, weeklyData);
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
    await _syncToFirestore(_weeklyDataKey, weeklyData);
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

    await _syncToFirestore(_weightKey, userData.weight);
    await _syncToFirestore(_heightKey, userData.height);
    await _syncToFirestore(_reminderMinutesKey, userData.reminderMinutes);
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
    await _syncToFirestore(_dailyGoalKey, dailyGoal);
  }

  Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 0;
  }

  Future<void> saveReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderMinutesKey, minutes);
    await _syncToFirestore(_reminderMinutesKey, minutes);
  }

  Future<int> getReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderMinutesKey) ?? 60;
  }

  Future<void> saveGlassesToday(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_glassesTodayKey, glasses);
    await _syncToFirestore(_glassesTodayKey, glasses);
  }

  Future<int> getGlassesToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_glassesTodayKey) ?? 0;
  }

  Future<void> saveGlassesYesterday(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_glassesYesterdayKey, glasses);
    await _syncToFirestore(_glassesYesterdayKey, glasses);
  }

  Future<int> getGlassesYesterday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_glassesYesterdayKey) ?? 0;
  }

  Future<void> saveLastDrinkAt(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDrinkAtKey, date.toIso8601String());
    await _syncToFirestore(_lastDrinkAtKey, date.toIso8601String());
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
    try {
      final doc = _userDoc;
      if (doc != null) {
        await doc.update({_lastDrinkAtKey: FieldValue.delete()});
      }
    } catch (e) {
      print('Error deleting lastDrinkAt on Firestore: $e');
    }
  }

  Future<void> saveLastReset(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetKey, date.toIso8601String());
    await _syncToFirestore(_lastResetKey, date.toIso8601String());
  }

  Future<DateTime?> getLastReset() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastResetKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
