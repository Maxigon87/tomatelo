import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:tomatelo/main.dart';
import 'package:tomatelo/models/nutrition_habit.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/screens/inicio_screen.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/utils/constants.dart';
import 'package:tomatelo/widgets/droplet_animation.dart';
import 'package:tomatelo/widgets/friendly_message.dart';
import 'package:tomatelo/widgets/hydration_pet.dart';
import 'package:tomatelo/widgets/nutrition_pet.dart';
import 'package:tomatelo/widgets/nutrition_tracker_card.dart';
import 'package:tomatelo/widgets/water_tracker_card.dart';
import 'package:tomatelo/widgets/water_radial_gauge.dart';
import 'package:tomatelo/widgets/water_timeline_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _storageService = StorageService();
  int _glassesToday = 0;
  int _dailyGoal = 0;
  List<int> _weeklyData = List.filled(7, 0);
  Map<String, int> _dailyHistory = {};
  bool _dropTrigger = false;
  bool _goalCelebrated = false;
  bool _tooMuchWaterWarned = false;
  DateTime _now = DateTime.now();
  late final Duration _hydrationRefresh;
  Widget? _friendlyMessage;
  DateTime? _lastDrinkAt;
  final PageController _pageController = PageController();
  late final ValueNotifier<double> _pagePosition;
  Map<String, int> _nutritionToday = {};
  Map<String, int> _nutritionGoals = {};
  Map<String, int> _nutritionYesterday = {};
  List<int> _nutritionWeeklyData = List.filled(7, 0);
  String _userName = '';
  int _lives = 1;
  String? _pendingLivesMessage;

  late final ConfettiController _confettiController;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hydrationRefresh = const Duration(minutes: 1);
    _pagePosition = ValueNotifier<double>(0);
    _pageController.addListener(_handlePageScroll);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeScreen();
    _startAdvisorRefresh();
    _listenToFirestore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _pageController
      ..removeListener(_handlePageScroll)
      ..dispose();
    _pagePosition.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeScreen();
    }
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients) {
      return;
    }
    _pagePosition.value = (_pageController.page ?? 0).clamp(0, 1).toDouble();
  }

  void _onSectionSelected(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _startAdvisorRefresh() {
    Future<void>.delayed(_hydrationRefresh, () {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
      _startAdvisorRefresh();
    });
  }

  void _listenToFirestore() {
    final stream = _storageService.getUserStream();
    if (stream == null) return;
    _userSubscription = stream.listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      _applyRemoteData(data);
    }, onError: (e) {
      debugPrint('Firestore stream error: $e');
    });
  }

  void _applyRemoteData(Map<String, dynamic> data) {
    final remoteGlasses = data['glassesToday'] as int?;
    final remoteGoal = data['dailyGoal'] as int?;
    final remoteName = data['name'] as String?;
    final remoteLives = (data['lives'] as num?)?.toInt();
    final remoteWeekly = (data['weeklyData'] as List?)?.map((e) => (e as num).toInt()).toList();
    final remoteHistory = (data['dailyHistory'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    final remoteNutritionToday = data['nutritionToday'] is Map
        ? _withDefaultNutritionValues(
            Map<String, int>.from(
              (data['nutritionToday'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            ),
          )
        : null;
    final remoteNutritionGoals = data['nutritionGoals'] is Map
        ? _withDefaultNutritionGoals(
            Map<String, int>.from(
              (data['nutritionGoals'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            ),
          )
        : null;
    final remoteNutritionYesterday = data['nutritionYesterday'] is Map
        ? _withDefaultNutritionValues(
            Map<String, int>.from(
              (data['nutritionYesterday'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            ),
          )
        : null;
    final remoteNutritionWeekly = (data['nutritionWeekly'] as List?)
        ?.map((e) => (e as num).toInt())
        .toList();

    if (!mounted) return;
    setState(() {
      if (remoteGlasses != null) _glassesToday = remoteGlasses;
      if (remoteGoal != null) _dailyGoal = remoteGoal;
      if (remoteName != null) _userName = remoteName;
      if (remoteLives != null) _lives = remoteLives;
      if (remoteWeekly != null && remoteWeekly.length == 7) {
        _weeklyData = remoteWeekly;
      }
      if (remoteHistory != null) {
        _dailyHistory = remoteHistory;
      }
      if (remoteNutritionToday != null) {
        _nutritionToday = remoteNutritionToday;
      }
      if (remoteNutritionGoals != null) {
        _nutritionGoals = remoteNutritionGoals;
      }
      if (remoteNutritionYesterday != null) {
        _nutritionYesterday = remoteNutritionYesterday;
      }
      if (remoteNutritionWeekly != null && remoteNutritionWeekly.length == 7) {
        _nutritionWeeklyData = remoteNutritionWeekly;
      }
      _now = DateTime.now();
    });
  }

  Future<void> _initializeScreen() async {
    await _storageService.syncFromFirestore();
    await _syncWeekAndDay();
    await _syncFromWidget();
    await _loadData();

    if (_pendingLivesMessage != null && mounted) {
      final msg = _pendingLivesMessage!;
      _pendingLivesMessage = null;
      Future.microtask(() {
        if (mounted) {
          _showLivesInfoDialog(msg);
        }
      });
    }
  }

  Future<void> _syncWeekAndDay() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr = "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";

    final storedLastReset = await _storageService.getLastReset();
    final storedWeekStart = await _storageService.getWeekStart();
    final storedDailyGoal = await _storageService.getDailyGoal();
    var dailyHistory = await _storageService.getDailyHistory();
    var weeklyData = await _storageService.getWeeklyData();
    var nutritionWeeklyData = await _storageService.getNutritionWeeklyData();

    if (weeklyData.length != 7) {
      weeklyData = List.filled(7, 0);
    }
    if (nutritionWeeklyData.length != 7) {
      nutritionWeeklyData = List.filled(7, 0);
    }

    final minMlForStreak = storedDailyGoal > 0 ? (storedDailyGoal * AppConstants.waterStep / 2).round() : AppConstants.waterStep;

    if (storedWeekStart != null && storedWeekStart != mondayStr) {
      // Comprobar si la semana anterior estuvo 100% completa (los 7 días al 50% o más)
      final isFullWeekCompleted = weeklyData.length == 7 && weeklyData.every((ml) => ml >= minMlForStreak && ml > 0);
      final lastAwarded = await _storageService.getLastAwardedWeek();

      if (isFullWeekCompleted && lastAwarded != storedWeekStart) {
        var currentLives = await _storageService.getLives();
        currentLives++;
        await _storageService.saveLives(currentLives);
        await _storageService.saveLastAwardedWeek(storedWeekStart);
        _pendingLivesMessage = "¡Semana perfecta completada! 🎉 Has ganado +1 Vida azul 💙. ¡Tu racha está más protegida que nunca!";
      }

      // La nueva semana comienza limpia de Lunes a Domingo
      weeklyData = List.filled(7, 0);
      nutritionWeeklyData = List.filled(7, 0);
      await _storageService.saveWeekStart(mondayStr);
    }

    if (storedLastReset != null &&
        (storedLastReset.day != now.day ||
         storedLastReset.month != now.month ||
         storedLastReset.year != now.year)) {
      final storedGlasses = await _storageService.getGlassesToday();
      final storedMl = storedGlasses * AppConstants.waterStep;
      final yesterdayKey = "${storedLastReset.year}-${storedLastReset.month.toString().padLeft(2, '0')}-${storedLastReset.day.toString().padLeft(2, '0')}";
      dailyHistory[yesterdayKey] = storedMl;
      await _storageService.saveDailyHistory(dailyHistory);
      await _storageService.saveGlassesYesterday(storedGlasses);
      await _storageService.saveGlassesToday(0);
      await _storageService.clearLastDrinkAt();

      // Comprobar si el día de ayer cumplió el 50%
      if (storedDailyGoal > 0 && storedMl < minMlForStreak) {
        var currentLives = await _storageService.getLives();
        if (currentLives > 0) {
          currentLives = max(0, currentLives - 1);
          await _storageService.saveLives(currentLives);
          _pendingLivesMessage = "¡Tu vida azul te salvó! 💙 No alcanzaste la meta de agua ayer, pero consumiste 1 vida para proteger tu racha sin perder tus días.";
        } else {
          _pendingLivesMessage = "¡Te quedaste sin vidas! 💔 Al no alcanzar la meta del 50% ayer, tu racha de días se ha reiniciado. ¡Inicia una nueva racha hoy!";
        }
      }

      final storedNutritionToday = _withDefaultNutritionValues(
        await _storageService.getNutritionToday(),
      );
      final storedNutritionGoals = _withDefaultNutritionGoals(
        await _storageService.getNutritionGoals(),
      );
      final nutWeekly = List<int>.from(
        await _storageService.getNutritionWeeklyData(),
      );
      if (nutWeekly.length == 7) {
        nutWeekly.removeAt(0);
        nutWeekly.add(
          _nutritionCompletedCount(storedNutritionToday, goals: storedNutritionGoals),
        );
        await _storageService.saveNutritionWeeklyData(nutWeekly);
      }
      await _storageService.saveNutritionYesterday(storedNutritionToday);
      await _storageService.saveNutritionToday(_emptyNutritionValues());

      await _storageService.saveLastReset(now);
    } else if (storedLastReset == null) {
      await _storageService.saveLastReset(now);
      await _storageService.saveWeekStart(mondayStr);
    }

    final currentGlasses = await _storageService.getGlassesToday();
    final todayIndex = now.weekday - 1;
    weeklyData[todayIndex] = currentGlasses * AppConstants.waterStep;

    final currentNutritionToday = _withDefaultNutritionValues(
      await _storageService.getNutritionToday(),
    );
    nutritionWeeklyData[todayIndex] = _nutritionCompletedCount(currentNutritionToday);

    for (int i = 0; i < todayIndex; i++) {
      final pastDate = DateTime(monday.year, monday.month, monday.day).add(Duration(days: i));
      final pastKey = "${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}";
      if (weeklyData[i] == 0 && dailyHistory.containsKey(pastKey)) {
        weeklyData[i] = dailyHistory[pastKey]!;
      }
    }

    await _storageService.saveWeeklyData(weeklyData);
    await _storageService.saveNutritionWeeklyData(nutritionWeeklyData);
  }

  Future<void> _syncFromWidget() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    final lastDate = await HomeWidget.getWidgetData<String>('lastDate', defaultValue: '');
    final currentDate = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != currentDate) {
      return;
    }

    final water = await HomeWidget.getWidgetData<int>('water', defaultValue: 0) ?? 0;
    final current = await _storageService.getGlassesToday();
    if (water > current) {
      await _storageService.saveGlassesToday(water);
    }
  }

  Future<void> _updateWidget(int water, int dailyGoal) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
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
    final userData = await _storageService.getUserData();
    final glassesToday = await _storageService.getGlassesToday();
    final dailyGoal = await _storageService.getDailyGoal();
    final weeklyData = await _storageService.getWeeklyData();
    final dailyHistory = await _storageService.getDailyHistory();
    final lastDrinkAt = await _storageService.getLastDrinkAt();
    final nutritionToday = _withDefaultNutritionValues(
      await _storageService.getNutritionToday(),
    );
    final storedGoals = await _storageService.getNutritionGoals();
    final nutritionGoals = _withDefaultNutritionGoals(storedGoals);
    final nutritionYesterday = _withDefaultNutritionValues(
      await _storageService.getNutritionYesterday(),
    );
    final lives = await _storageService.getLives();
    final nutritionWeeklyData = await _storageService.getNutritionWeeklyData();
    if (storedGoals.isEmpty) {
      await _storageService.saveNutritionGoals(nutritionGoals);
    }

    if (!mounted) return;
    setState(() {
      if (userData != null) {
        _userName = userData.name;
      }
      _lives = lives;
      _glassesToday = glassesToday;
      _dailyGoal = dailyGoal;
      _weeklyData = weeklyData;
      _dailyHistory = dailyHistory;
      _goalCelebrated = glassesToday >= dailyGoal && dailyGoal > 0;
      _tooMuchWaterWarned = false;
      _now = DateTime.now();
      _lastDrinkAt = lastDrinkAt;
      _nutritionToday = nutritionToday;
      _nutritionGoals = nutritionGoals;
      _nutritionYesterday = nutritionYesterday;
      _nutritionWeeklyData = nutritionWeeklyData;
    });
    await _updateWidget(_glassesToday, _dailyGoal);
  }

  String get _userInitials {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _showLivesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: AppTheme.primaryAqua, size: 28),
              SizedBox(width: 10),
              Text(
                'Vidas de Racha 💙',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tienes $_lives ${(_lives == 1) ? 'vida disponible' : 'vidas disponibles'} 💙',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryAqua,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '• ¡Completa los 7 días de una semana entera (al 50% o más de tu meta de agua) y ganarás +1 Vida extra! 🏆\n\n'
                '• Si un día no logras el 50% de tu objetivo, usarás 1 vida automáticamente para proteger tu racha sin perder tus días. 🔥\n\n'
                '• Si te quedas sin vidas y no alcanzas el 50%, tu racha se reiniciará.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '¡Entendido!',
                style: TextStyle(color: AppTheme.primaryAqua, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLivesInfoDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: AppTheme.primaryAqua, size: 26),
              SizedBox(width: 10),
              Text(
                'Notificación de Racha',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.onSurface,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: AppTheme.primaryAqua, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  int get _upperHydrationLimit {
    if (_dailyGoal <= 0) {
      return 0;
    }
    return _dailyGoal + 3;
  }

  void _showFriendlyMessage({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    setState(() {
      _friendlyMessage = FriendlyMessage(
        title: title,
        message: message,
        icon: icon,
        color: color,
        onDismiss: () {
          setState(() {
            _friendlyMessage = null;
          });
        },
      );
    });
  }

  void _incrementGlasses() {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final newGlasses = _glassesToday + 1;
    final newWeekly = List<int>.from(_weeklyData);
    if (newWeekly.length == 7) {
      newWeekly[todayIndex] = newGlasses * AppConstants.waterStep;
    }

    final todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final updatedHistory = Map<String, int>.from(_dailyHistory);
    updatedHistory[todayKey] = newGlasses * AppConstants.waterStep;

    setState(() {
      _glassesToday = newGlasses;
      _weeklyData = newWeekly;
      _dailyHistory = updatedHistory;
      _dropTrigger = !_dropTrigger;
      _now = now;
      _lastDrinkAt = _now;
    });

    _storageService.saveGlassesToday(_glassesToday);
    _storageService.saveWeeklyData(newWeekly);
    _storageService.saveDailyHistory(updatedHistory);
    _storageService.saveLastDrinkAt(_lastDrinkAt!);
    _updateWidget(_glassesToday, _dailyGoal);

    if (_dailyGoal > 0 && _glassesToday >= _dailyGoal && !_goalCelebrated) {
      _goalCelebrated = true;
      _showFriendlyMessage(
        title: '¡Meta cumplida! 🎉',
        message:
            '¡Excelente! Ya llegaste a tu objetivo de hoy. Ahora mantén un ritmo tranqui y escucha a tu cuerpo. 💧',
        icon: Icons.celebration_rounded,
        color: AppTheme.primaryBlue,
      );
    }

    if (_upperHydrationLimit > 0 &&
        _glassesToday >= _upperHydrationLimit &&
        !_tooMuchWaterWarned) {
      _tooMuchWaterWarned = true;
      _showFriendlyMessage(
        title: 'Ojo, súper hidratado 😅',
        message:
            'Ya vas $_glassesToday vasos (límite sugerido: $_upperHydrationLimit). Mejor bajemos el ritmo para no pasarnos con el agua hoy.',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
      );
    }
  }

  Future<void> _decrementGlasses() async {
    if (_glassesToday <= 0) {
      return;
    }

    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final newGlasses = _glassesToday - 1;
    final newWeekly = List<int>.from(_weeklyData);
    if (newWeekly.length == 7) {
      newWeekly[todayIndex] = newGlasses * AppConstants.waterStep;
    }

    final todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final updatedHistory = Map<String, int>.from(_dailyHistory);
    updatedHistory[todayKey] = newGlasses * AppConstants.waterStep;

    setState(() {
      _glassesToday = newGlasses;
      _weeklyData = newWeekly;
      _dailyHistory = updatedHistory;
      _now = now;
      if (_glassesToday < _dailyGoal) {
        _goalCelebrated = false;
      }
      if (_glassesToday < _upperHydrationLimit) {
        _tooMuchWaterWarned = false;
      }
      if (_glassesToday == 0) {
        _lastDrinkAt = null;
      }
    });

    await _storageService.saveGlassesToday(_glassesToday);
    await _storageService.saveWeeklyData(newWeekly);
    await _storageService.saveDailyHistory(updatedHistory);
    if (_lastDrinkAt == null) {
      await _storageService.clearLastDrinkAt();
    }
    await _updateWidget(_glassesToday, _dailyGoal);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _pagePosition,
      builder: (context, position, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: AppTheme.background.withValues(alpha: 0.85),
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppTheme.primaryAqua,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_waterStreak días',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryAqua,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 16,
                  color: AppTheme.surfaceHighest,
                ),
                const SizedBox(width: 8),
                Text(
                  position < 0.5 ? 'Agua Pura' : 'Frutas & Té',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: _showLivesDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.primaryAqua.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: AppTheme.primaryAqua,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_lives',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryAqua,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryAqua,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _userInitials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00354A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceVariant),
                color: AppTheme.surfaceHigh,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'info') {
                    _showFriendlyMessage(
                      title: _pagePosition.value < 0.5
                          ? 'Consejo de hidratación'
                          : 'Consejo de nutrición',
                      message: _pagePosition.value < 0.5
                          ? '¡Vas increíble! Bebe agua de a poco durante el día y tu cuerpo te lo va a aplaudir. 👏'
                          : 'Suma hábitos simples y amables: una fruta, una infusión o un snack saludable. Sin culpa, paso a paso. 🍎',
                      icon: Icons.info_outline_rounded,
                      color: _activeAccentColor,
                    );
                    return;
                  }

                  if (value == 'theme') {
                    final current = themeModeNotifier.value;
                    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                    themeModeNotifier.value = next;
                    await _storageService.saveThemeMode(next == ThemeMode.dark ? 'dark' : 'light');
                    return;
                  }

                  if (value == 'settings') {
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    final updated = await SetupScreen.showModal(context);
                    if (updated == true && mounted) {
                      await _loadData();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppTheme.tertiaryMint),
                                SizedBox(width: 10),
                                Text(
                                  'Meta de agua y recordatorios sincronizados 💧',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.surfaceHigh,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    }
                  }

                  if (value == 'logout') {
                    if (!context.mounted) return;
                    final navigator = Navigator.of(context);
                    await FirebaseAuth.instance.signOut();
                    await StorageService().clearAll();
                    if (!context.mounted) return;
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const InicioScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: AppTheme.primaryAqua),
                      title: Text('Información', style: TextStyle(fontWeight: FontWeight.w600)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'theme',
                    child: ListTile(
                      leading: Icon(
                        themeModeNotifier.value == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppTheme.primaryAqua,
                      ),
                      title: Text(
                        themeModeNotifier.value == ThemeMode.dark
                            ? 'Modo Claro'
                            : 'Modo Oscuro',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined, color: AppTheme.primaryAqua),
                      title: Text('Configuración', style: TextStyle(fontWeight: FontWeight.w600)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded, color: AppTheme.secondaryCoral),
                      title: Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _SwipeBackground(
            pagePosition: position,
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    RepaintBoundary(child: _buildWaterPage(context)),
                    RepaintBoundary(child: _buildNutritionPage(context)),
                  ],
                ),
                DropletAnimation(trigger: _dropTrigger),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.yellow,
                    ],
                  ),
                ),
                if (_friendlyMessage != null) _friendlyMessage!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterPage(BuildContext context) {
    final currentMl = _mlFromGlasses(_glassesToday).round();
    final targetMl = (_dailyGoal * AppConstants.waterStep).round();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16,
          right: 16,
          bottom: 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dynamic Category Switcher Capsule
            _SectionPill(
              pagePosition: _pagePosition.value,
              activeColor: _activeAccentColor,
              onSectionSelected: _onSectionSelected,
            ),
            const SizedBox(height: 14),
            // Hero Hydration Card with Bioluminescent Glow & Gotita & Gauge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.surfaceContainer,
                    AppTheme.surfaceLow,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  RepaintBoundary(
                    child: HydrationPet(
                      mood: _petMood,
                      size: 140,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WaterRadialGauge(
                    currentMl: currentMl,
                    targetMl: targetMl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Quick-Log Pill Action Zone
            QuickLogPillCard(
              onAddWaterMl: (ml) {
                final count = (ml / AppConstants.waterStep).round().clamp(1, 4);
                for (var i = 0; i < count; i++) {
                  _incrementGlasses();
                }
              },
              onUndo: _decrementGlasses,
              weeklyData: _weeklyData,
            ),
            const SizedBox(height: 14),
            // Guía de Tomar Agua (Camino ideal vs. Progreso real)
            RepaintBoundary(
              child: WaterTimelineChart(
                dailyGoalMl: targetMl,
                glassesToday: _glassesToday,
                lastDrinkAt: _lastDrinkAt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionPage(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16,
          right: 16,
          bottom: 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dynamic Category Switcher Capsule
            _SectionPill(
              pagePosition: _pagePosition.value,
              activeColor: _activeAccentColor,
              onSectionSelected: _onSectionSelected,
            ),
            const SizedBox(height: 14),
            RepaintBoundary(
              child: NutritionPet(
                mood: _nutritionPetMood,
                progress: _nutritionProgress,
                size: 140,
              ),
            ),
            const SizedBox(height: 16),
            NutritionTrackerCard(
              today: _nutritionToday,
              goals: _nutritionGoals,
              completed: _nutritionCompleted,
              totalGoal: _nutritionGoalTotal,
              onAddHabit: _incrementNutritionHabit,
              onOpenGoals: _showNutritionGoalsSheet,
              yesterdayData: _nutritionYesterday,
              weeklyData: _nutritionWeeklyData,
            ),
          ],
        ),
      ),
    );
  }


  Color get _activeAccentColor {
    return Color.lerp(
      AppTheme.primaryAqua,
      AppTheme.secondaryCoral,
      _pagePosition.value.clamp(0.0, 1.0),
    )!;
  }

  int get _nutritionCompleted => _nutritionCompletedCount(_nutritionToday);

  int get _nutritionGoalTotal => nutritionHabits.fold(
        0,
        (total, habit) => total + (_nutritionGoals[habit.id] ?? habit.defaultGoal),
      );

  double get _nutritionProgress {
    if (_nutritionGoalTotal <= 0) return 0;
    return (_nutritionCompleted / _nutritionGoalTotal).clamp(0, 1).toDouble();
  }

  Map<String, int> _emptyNutritionValues() => {
        for (final habit in nutritionHabits) habit.id: 0,
      };

  Map<String, int> _withDefaultNutritionValues(Map<String, int> values) => {
        for (final habit in nutritionHabits) habit.id: values[habit.id] ?? 0,
      };

  Map<String, int> _withDefaultNutritionGoals(Map<String, int> goals) => {
        for (final habit in nutritionHabits)
          habit.id: (goals[habit.id] ?? habit.defaultGoal).clamp(0, 8).toInt(),
      };

  int _nutritionCompletedCount(
    Map<String, int> values, {
    Map<String, int>? goals,
  }) {
    final activeGoals = goals ?? _nutritionGoals;
    return nutritionHabits.fold(0, (total, habit) {
      final count = values[habit.id] ?? 0;
      final goal = activeGoals[habit.id] ?? habit.defaultGoal;
      return total + count.clamp(0, goal).toInt();
    });
  }

  void _incrementNutritionHabit(NutritionHabit habit) {
    final updatedToday = Map<String, int>.from(_nutritionToday)
      ..[habit.id] = (_nutritionToday[habit.id] ?? 0) + 1;

    final completedCount = _nutritionCompletedCount(updatedToday);
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final newWeekly = List<int>.from(_nutritionWeeklyData);
    if (newWeekly.length == 7) {
      newWeekly[todayIndex] = completedCount;
    }

    setState(() {
      _nutritionToday = updatedToday;
      _nutritionWeeklyData = newWeekly;
    });

    _storageService.saveNutritionToday(updatedToday);
    _storageService.saveNutritionWeeklyData(newWeekly);

    final goal = _nutritionGoals[habit.id] ?? habit.defaultGoal;
    final count = updatedToday[habit.id] ?? 0;
    if (count == goal) {
      _showFriendlyMessage(
        title: 'Hábito completado ${habit.emoji}',
        message: '¡Qué lindo! Ya sumaste ${habit.label.toLowerCase()} hoy. Seguimos suave, sin presión.',
        icon: habit.icon,
        color: const Color(0xFF7CB342),
      );
    }
  }

  void _showNutritionGoalsSheet() {
    final draftGoals = Map<String, int>.from(_nutritionGoals);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Objetivos saludables',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ajusta metas simples para tu día. Sin calorías ni presión.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...nutritionHabits.map((habit) {
                    final value = draftGoals[habit.id] ?? habit.defaultGoal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(habit.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              habit.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.surfaceContainer,
                              foregroundColor: AppTheme.primaryAqua,
                            ),
                            onPressed: value > 0
                                ? () => setSheetState(() => draftGoals[habit.id] = value - 1)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          SizedBox(
                            width: 34,
                            child: Text(
                              '$value',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.surfaceContainer,
                              foregroundColor: AppTheme.primaryAqua,
                            ),
                            onPressed: value < 8
                                ? () => setSheetState(() => draftGoals[habit.id] = value + 1)
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryCoral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _nutritionGoals = _withDefaultNutritionGoals(draftGoals));
                        _storageService.saveNutritionGoals(_nutritionGoals);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Guardar objetivos',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _mlFromGlasses(int glasses) =>
      (glasses * AppConstants.waterStep).toDouble();

  // La gota refleja en tiempo real el progreso de hidratación según la hora del día.
  // Si ha tomado suficiente agua para el avance esperado del día, está feliz.
  // Si no ha tomado agua suficiente a medida que avanza el día, se pone triste / sedienta.
  HydrationPetMood get _petMood {
    if (_dailyGoal <= 0) return HydrationPetMood.happy;
    if (_glassesToday >= _dailyGoal) return HydrationPetMood.happy;

    final now = DateTime.now();
    // Antes de las 8:00 AM, recién comienza la mañana
    if (now.hour < 8) return HydrationPetMood.happy;

    // Jornada activa entre las 8:00 y las 22:00 (14 horas activas)
    final elapsedHours = (now.hour - 8) + (now.minute / 60.0);
    const totalActiveHours = 14.0;
    final expectedFraction = (elapsedHours / totalActiveHours).clamp(0.0, 1.0);
    final expectedGlasses = _dailyGoal * expectedFraction;

    if (_glassesToday >= (expectedGlasses * 0.75)) {
      return HydrationPetMood.happy;
    } else if (_glassesToday >= (expectedGlasses * 0.50)) {
      return HydrationPetMood.normal;
    } else {
      return HydrationPetMood.tired;
    }
  }

  int get _waterStreak {
    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = now;

    // Se requiere al menos el 50% (la MITAD) del objetivo diario para sumar racha
    final minGlassesForStreak = _dailyGoal > 0 ? (_dailyGoal / 2).ceil() : 1;

    if (_dailyGoal > 0 && _glassesToday >= minGlassesForStreak) {
      streak++;
      checkDate = now.subtract(const Duration(days: 1));
    } else {
      checkDate = now.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      final ml = _dailyHistory[key] ?? 0;
      final glasses = (ml / AppConstants.waterStep).round();
      if (_dailyGoal > 0 && glasses >= minGlassesForStreak) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // La manzana/fruta refleja la nutrición y salud según el momento del día y progreso.
  // Si empezó bien pero ya es la tarde/noche y no consumió hábitos suficientes, se pone triste.
  NutritionPetMood get _nutritionPetMood {
    final now = DateTime.now();
    final progress = _nutritionProgress;

    // Antes de las 8:00 AM, la mañana apenas comienza
    if (now.hour < 8) return NutritionPetMood.happy;

    // Jornada activa de 8:00 AM a 22:00 PM (14 horas activas)
    final elapsedHours = (now.hour - 8) + (now.minute / 60.0);
    const totalActiveHours = 14.0;
    final expectedFraction = (elapsedHours / totalActiveHours).clamp(0.0, 1.0);

    if (progress >= 1.0 || progress >= expectedFraction) {
      return NutritionPetMood.happy;
    }
    if (progress >= (expectedFraction * 0.50)) {
      return NutritionPetMood.normal;
    }
    return NutritionPetMood.tired;
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.pagePosition, required this.child});

  final double pagePosition;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterColors = isDark
        ? const [Color(0xFF071726), Color(0xFF0E3658), Color(0xFF164A73)]
        : const [Color(0xFFEFF8FF), Color(0xFFDDF2FF), Colors.white];
    final nutritionColors = isDark
        ? const [Color(0xFF101F13), Color(0xFF27451F), Color(0xFF5B3A16)]
        : const [Color(0xFFF4FFE8), Color(0xFFFFF2CC), Colors.white];

    final currentColors = List.generate(
      waterColors.length,
      (index) => Color.lerp(
        waterColors[index],
        nutritionColors[index],
        pagePosition.clamp(0.0, 1.0),
      )!,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({
    required this.pagePosition,
    required this.activeColor,
    required this.onSectionSelected,
  });

  final double pagePosition;
  final Color activeColor;
  final ValueChanged<int> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillItem(
              label: 'Agua Pura',
              icon: Icons.water_drop_rounded,
              selected: pagePosition < 0.5,
              activeColor: AppTheme.primaryAqua,
              onTap: () => onSectionSelected(0),
            ),
          ),
          Expanded(
            child: _PillItem(
              label: 'Frutas & Té',
              icon: Icons.eco_rounded,
              selected: pagePosition >= 0.5,
              activeColor: AppTheme.secondaryCoral,
              onTap: () => onSectionSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.surfaceBright : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? activeColor : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : AppTheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
