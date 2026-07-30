import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:tomatelo/models/nutrition_habit.dart';
import 'package:tomatelo/models/pet_state.dart';
import 'package:tomatelo/models/user_data.dart';
import 'package:tomatelo/screens/profile_screen.dart';
import 'package:tomatelo/screens/stats_screen.dart';
import 'package:tomatelo/services/health_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/widgets/hydration_pet.dart';
import 'package:tomatelo/widgets/movement_pet.dart';
import 'package:tomatelo/widgets/nutrition_pet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _storageService = StorageService();

  int _currentNavIndex = 0;

  // Hydration state
  int _glassesToday = 0;
  int _dailyGoalGlasses = 8;
  List<int> _waterWeekly = List.filled(7, 0);

  // Nutrition state
  Map<String, int> _nutritionToday = {};
  Map<String, int> _nutritionGoals = {};
  List<int> _nutritionWeekly = List.filled(7, 0);

  // Movement state
  int _movementStepsToday = 0;
  int _movementGoalSteps = 8000;
  List<int> _movementWeekly = List.filled(7, 0);

  UserData? _userData;
  bool _healthConnectLinked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeScreen();
    }
  }

  Future<void> _initializeScreen() async {
    await _resetDataAtMidnight();
    await _syncFromWidget();
    await _loadData();
  }

  Future<void> _syncFromWidget() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    final lastDate = await HomeWidget.getWidgetData<String>('lastDate', defaultValue: '');
    final currentDate = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != currentDate) return;

    final water = await HomeWidget.getWidgetData<int>('water', defaultValue: 0) ?? 0;
    final current = await _storageService.getGlassesToday();
    if (water > current) {
      await _storageService.saveGlassesToday(water);
    }
  }

  Future<void> _updateWidget(int water, int dailyGoal) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    await HomeWidget.saveWidgetData('water', water);
    await HomeWidget.saveWidgetData('goal', dailyGoal);
    await HomeWidget.saveWidgetData('lastDate', currentDate);
    await HomeWidget.updateWidget(
      androidName: 'WaterWidgetProvider',
      qualifiedAndroidName: 'com.example.tomatelo.WaterWidgetProvider',
    );
  }

  Future<void> _loadData() async {
    final glassesToday = await _storageService.getGlassesToday();
    final dailyGoal = await _storageService.getDailyGoal();
    final weeklyData = await _storageService.getWeeklyData();

    final nutritionToday = _withDefaultNutritionValues(
      await _storageService.getNutritionToday(),
    );
    final storedGoals = await _storageService.getNutritionGoals();
    final nutritionGoals = _withDefaultNutritionGoals(storedGoals);
    final nutritionWeeklyData = await _storageService.getNutritionWeeklyData();

    final movementGoal = await _storageService.getMovementGoal();
    final movementSteps = await _storageService.getMovementSteps();
    final movementWeeklyData = await _storageService.getMovementWeeklyData();
    final healthConnectLinked = await _storageService.isHealthConnectLinked();
    final userData = await _storageService.getUserData();

    if (!mounted) return;
    setState(() {
      _glassesToday = glassesToday;
      _dailyGoalGlasses = dailyGoal > 0 ? dailyGoal : 8;
      _waterWeekly = weeklyData;
      _nutritionToday = nutritionToday;
      _nutritionGoals = nutritionGoals;
      _nutritionWeekly = nutritionWeeklyData;
      _movementGoalSteps = movementGoal > 0 ? movementGoal : 8000;
      _movementStepsToday = movementSteps;
      _movementWeekly = movementWeeklyData;
      _healthConnectLinked = healthConnectLinked;
      _userData = userData;
    });

    await _updateWidget(_glassesToday, _dailyGoalGlasses);
    if (healthConnectLinked) {
      await _fetchHealthConnectData();
    }
  }

  Future<void> _resetDataAtMidnight() async {
    final lastReset = await _storageService.getLastReset();
    final now = DateTime.now();
    final storedGlassesToday = await _storageService.getGlassesToday();
    final storedNutritionToday = _withDefaultNutritionValues(
      await _storageService.getNutritionToday(),
    );

    if (lastReset == null) {
      await _storageService.saveLastReset(now);
      return;
    }

    if (now.day != lastReset.day ||
        now.month != lastReset.month ||
        now.year != lastReset.year) {
      final weeklyData = List<int>.from(await _storageService.getWeeklyData());
      weeklyData.removeAt(0);
      weeklyData.add(storedGlassesToday * 250);
      await _storageService.saveWeeklyData(weeklyData);

      final nutritionWeeklyData = List<int>.from(
        await _storageService.getNutritionWeeklyData(),
      );
      nutritionWeeklyData.removeAt(0);
      nutritionWeeklyData.add(
        _nutritionCompletedCount(storedNutritionToday),
      );
      await _storageService.saveNutritionWeeklyData(nutritionWeeklyData);

      await _storageService.saveGlassesToday(0);
      await _storageService.saveNutritionToday(_emptyNutritionValues());

      final storedMovementSteps = await _storageService.getMovementSteps();
      final movementWeeklyData = List<int>.from(await _storageService.getMovementWeeklyData());
      movementWeeklyData.removeAt(0);
      movementWeeklyData.add(storedMovementSteps);
      await _storageService.saveMovementWeeklyData(movementWeeklyData);
      await _storageService.saveMovementSteps(0);

      await _storageService.saveLastReset(now);
    }
  }

  Future<void> _fetchHealthConnectData() async {
    final healthService = HealthService.instance;
    final hasPermissions = await healthService.requestPermissions();
    if (!hasPermissions) return;

    final data = await healthService.fetchTodayData();
    final steps = data['steps'] ?? 0;
    if (steps > _movementStepsToday) {
      setState(() {
        _movementStepsToday = steps;
      });
      await _storageService.saveMovementSteps(steps);
    }
  }

  Map<String, int> _withDefaultNutritionValues(Map<String, int> values) {
    final result = Map<String, int>.from(values);
    for (final habit in defaultNutritionHabits) {
      result.putIfAbsent(habit.id, () => 0);
    }
    return result;
  }

  Map<String, int> _withDefaultNutritionGoals(Map<String, int> goals) {
    final result = Map<String, int>.from(goals);
    for (final habit in defaultNutritionHabits) {
      result.putIfAbsent(habit.id, () => habit.defaultGoal);
    }
    return result;
  }

  Map<String, int> _emptyNutritionValues() {
    final map = <String, int>{};
    for (final habit in defaultNutritionHabits) {
      map[habit.id] = 0;
    }
    return map;
  }

  int _nutritionCompletedCount(Map<String, int> habits) {
    return habits.values.where((count) => count > 0).length;
  }

  Future<void> _addWater(int glasses) async {
    final updated = (_glassesToday + glasses).clamp(0, 30);
    setState(() => _glassesToday = updated);
    await _storageService.saveGlassesToday(updated);
    await _updateWidget(updated, _dailyGoalGlasses);
  }

  Future<void> _toggleNutritionHabit(String habitId) async {
    final current = _nutritionToday[habitId] ?? 0;
    final updated = current > 0 ? 0 : 1;
    final map = Map<String, int>.from(_nutritionToday);
    map[habitId] = updated;
    setState(() => _nutritionToday = map);
    await _storageService.saveNutritionToday(map);
  }

  Future<void> _addSteps(int delta) async {
    final updated = (_movementStepsToday + delta).clamp(0, 100000);
    setState(() => _movementStepsToday = updated);
    await _storageService.saveMovementSteps(updated);
  }

  int _calculateStreakDays() {
    int streak = 0;
    if (_glassesToday >= _dailyGoalGlasses) streak++;
    for (int i = _waterWeekly.length - 1; i >= 0; i--) {
      if (_waterWeekly[i] >= (_dailyGoalGlasses * 250)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // Pet Mood Evaluations
  PetMood get _hydrationPetMood {
    return PetStateEngine.evaluateHydration(
      currentMl: _glassesToday * 250,
      goalMl: _dailyGoalGlasses * 250,
    );
  }

  PetMood get _nutritionPetMood {
    return PetStateEngine.evaluateNutrition(
      todayHabits: _nutritionToday,
      goalHabits: _nutritionGoals,
    );
  }

  PetMood get _movementPetMood {
    return PetStateEngine.evaluateMovement(
      currentSteps: _movementStepsToday,
      goalSteps: _movementGoalSteps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = _calculateStreakDays();

    return Scaffold(
      body: UnifiedBackground(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            // Tab 0: Unified Vertical Bento Dashboard (Día)
            _buildDashboardView(streak),

            // Tab 1: Estadísticas (Stats & History)
            StatsScreen(
              waterWeekly: _waterWeekly,
              nutritionWeekly: _nutritionWeekly,
              movementWeekly: _movementWeekly,
              streakDays: streak,
            ),

            // Tab 2: Perfil (Settings & Guardians)
            ProfileScreen(
              hydrationMood: _hydrationPetMood,
              nutritionMood: _nutritionPetMood,
              movementMood: _movementPetMood,
              dailyGoalGlasses: _dailyGoalGlasses,
              movementGoalSteps: _movementGoalSteps,
              userData: _userData,
              onDataChanged: _loadData,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Día',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(int streak) {
    final currentMl = _glassesToday * 250;
    final goalMl = _dailyGoalGlasses * 250;
    final hydrationRatio = (currentMl / (goalMl > 0 ? goalMl : 2000)).clamp(0.0, 1.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header & Streak Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '¡Hola, bienvenido! 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tus mascotas cuentan contigo hoy',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '$streak d',
                        style: const TextStyle(
                          color: Color(0xFFFF5722),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hero Hydration Ring Card with Gota-Bot
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '💧 Hidratación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _hydrationPetMood.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Gota-Bot Pet Widget
                      HydrationPet(
                        mood: _hydrationPetMood,
                        size: 110,
                        progress: hydrationRatio,
                      ),
                      const SizedBox(width: 20),
                      // Progress Ring & Counter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currentMl / $goalMl ml',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: hydrationRatio,
                                minHeight: 12,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_glassesToday de $_dailyGoalGlasses vasos hoy',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick Add Water Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addWater(1),
                          icon: const Icon(Icons.local_drink_rounded, color: AppTheme.hydrationDark),
                          label: const Text(
                            '+250 ml',
                            style: TextStyle(
                              color: AppTheme.hydrationDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addWater(2),
                          icon: const Icon(Icons.water_drop_rounded, color: AppTheme.hydrationDark),
                          label: const Text(
                            '+500 ml',
                            style: TextStyle(
                              color: AppTheme.hydrationDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bento Cards (Nutrición & Movimiento)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nutrition Bento Card (Broto)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.nutritionPrimary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.nutritionPrimary.withValues(alpha: 0.08),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🥗 Nutrición',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.nutritionDark,
                              ),
                            ),
                            Text(
                              '${_nutritionCompletedCount(_nutritionToday)} / ${defaultNutritionHabits.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.nutritionPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: NutritionPet(
                            mood: _nutritionPetMood,
                            size: 85,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: defaultNutritionHabits.map((habit) {
                            final isChecked = (_nutritionToday[habit.id] ?? 0) > 0;
                            return InkWell(
                              onTap: () => _toggleNutritionHabit(habit.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      isChecked ? Icons.check_circle_rounded : Icons.circle_outlined,
                                      color: isChecked ? AppTheme.nutritionPrimary : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${habit.icon} ${habit.name}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                          decoration: isChecked ? TextDecoration.lineThrough : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Movement Bento Card (Zorro Veloz)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.movementPrimary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.movementPrimary.withValues(alpha: 0.08),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🏃 Pasos',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.movementDark,
                              ),
                            ),
                            Icon(
                              _healthConnectLinked ? Icons.sync : Icons.directions_walk_rounded,
                              size: 16,
                              color: AppTheme.movementPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: MovementPet(
                            mood: _movementPetMood,
                            size: 85,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_movementStepsToday',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppTheme.movementDark,
                          ),
                        ),
                        Text(
                          'de $_movementGoalSteps pasos',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _addSteps(500),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.movementPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '+500 pasos',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
