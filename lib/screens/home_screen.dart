import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:tomatelo/models/nutrition_habit.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/screens/inicio_screen.dart';
import 'package:tomatelo/services/hydration_engine.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/services/health_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/utils/constants.dart';
import 'package:tomatelo/widgets/droplet_animation.dart';
import 'package:tomatelo/widgets/friendly_message.dart';
import 'package:tomatelo/widgets/hydration_pet.dart';
import 'package:tomatelo/widgets/nutrition_pet.dart';
import 'package:tomatelo/widgets/movement_pet.dart';
import 'package:tomatelo/widgets/nutrition_tracker_card.dart';
import 'package:tomatelo/widgets/water_tracker_card.dart';
import 'package:tomatelo/widgets/movement_tracker_card.dart';
import 'package:tomatelo/widgets/weekly_chart.dart';
import 'package:tomatelo/widgets/water_radial_gauge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _storageService = StorageService();
  final _hydrationEngine = const HydrationEngine();
  final _notificationService = NotificationService.instance;
  int _glassesToday = 0;
  int _glassesYesterday = 0;
  int _dailyGoal = 0;
  List<int> _weeklyData = List.filled(7, 0);
  bool _dropTrigger = false;
  bool _goalCelebrated = false;
  bool _tooMuchWaterWarned = false;
  HydrationAdvice? _hydrationAdvice;
  late DateTime _dayStartTime;
  late DateTime _dayEndTime;
  DateTime _now = DateTime.now();
  late final Duration _hydrationRefresh;
  Widget? _friendlyMessage;
  ReminderSuggestion? _reminderSuggestion;
  DateTime? _lastDrinkAt;
  final PageController _pageController = PageController();
  late final ValueNotifier<double> _pagePosition;
  Map<String, int> _nutritionToday = {};
  Map<String, int> _nutritionGoals = {};
  Map<String, int> _nutritionYesterday = {};
  List<int> _nutritionWeeklyData = List.filled(7, 0);

  late final ConfettiController _confettiController;
  int _movementMinutesToday = 0;
  int _movementStepsToday = 0;
  int _movementGoal = 30;
  int _movementYesterday = 0;
  List<int> _movementWeeklyData = List.filled(7, 0);
  List<String> _movementHistory = [];
  bool _healthConnectLinked = false;
  bool _movementCelebrated = false;
  bool _healthConnectAvailable = false;

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
    _checkHealthConnectAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _pagePosition.value = (_pageController.page ?? 0).clamp(0, 2).toDouble();
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
        _refreshHydrationAdvice();
      });
      _startAdvisorRefresh();
    });
  }

  void _refreshHydrationAdvice() {
    if (_dailyGoal <= 0) {
      _hydrationAdvice = null;
      _reminderSuggestion = null;
      return;
    }

    final totalMl = _dailyGoal * AppConstants.waterStep;
    final consumedMl = _glassesToday * AppConstants.waterStep;

    _hydrationAdvice = _hydrationEngine.calculate(
      totalMl: totalMl.toDouble(),
      consumedMl: consumedMl.toDouble(),
      startTime: _dayStartTime,
      endTime: _dayEndTime,
      now: _now,
    );
    _reminderSuggestion = _notificationService.buildSuggestion(
      now: _now,
      fallbackMinutes: 60,
      hydrationAdvice: _hydrationAdvice,
    );
  }

  Future<void> _initializeScreen() async {
    final today = DateTime.now();
    _dayStartTime = DateTime(today.year, today.month, today.day, 8);
    _dayEndTime = DateTime(today.year, today.month, today.day, 22);
    await _resetDataAtMidnight();
    await _syncFromWidget();
    await _loadData();
  }

  Future<void> _syncFromWidget() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    final lastDate = await HomeWidget.getWidgetData<String>('lastDate', defaultValue: '');
    final currentDate = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != currentDate) {
      return; // Do not sync yesterday's widget data on a new day
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
    final glassesToday = await _storageService.getGlassesToday();
    final glassesYesterday = await _storageService.getGlassesYesterday();
    final dailyGoal = await _storageService.getDailyGoal();
    final weeklyData = await _storageService.getWeeklyData();
    final lastDrinkAt = await _storageService.getLastDrinkAt();
    final nutritionToday = _withDefaultNutritionValues(
      await _storageService.getNutritionToday(),
    );
    final storedGoals = await _storageService.getNutritionGoals();
    final nutritionGoals = _withDefaultNutritionGoals(storedGoals);
    final nutritionYesterday = _withDefaultNutritionValues(
      await _storageService.getNutritionYesterday(),
    );
    final nutritionWeeklyData = await _storageService.getNutritionWeeklyData();
    if (storedGoals.isEmpty) {
      await _storageService.saveNutritionGoals(nutritionGoals);
    }

    final movementGoal = await _storageService.getMovementGoal();
    final movementMinutes = await _storageService.getMovementMinutes();
    final movementSteps = await _storageService.getMovementSteps();
    final movementYesterday = await _storageService.getMovementYesterday();
    final movementWeeklyData = await _storageService.getMovementWeeklyData();
    final movementHistory = await _storageService.getMovementHistory();
    final healthConnectLinked = await _storageService.isHealthConnectLinked();

    if (!mounted) return;
    setState(() {
      _glassesToday = glassesToday;
      _glassesYesterday = glassesYesterday;
      _dailyGoal = dailyGoal;
      _weeklyData = weeklyData;
      _goalCelebrated = glassesToday >= dailyGoal && dailyGoal > 0;
      _tooMuchWaterWarned = false;
      _now = DateTime.now();
      _lastDrinkAt = lastDrinkAt;
      _nutritionToday = nutritionToday;
      _nutritionGoals = nutritionGoals;
      _nutritionYesterday = nutritionYesterday;
      _nutritionWeeklyData = nutritionWeeklyData;
      _refreshHydrationAdvice();

      _movementGoal = movementGoal;
      _movementMinutesToday = movementMinutes;
      _movementStepsToday = movementSteps;
      _movementYesterday = movementYesterday;
      _movementWeeklyData = movementWeeklyData;
      _movementHistory = movementHistory;
      _healthConnectLinked = healthConnectLinked;
      _movementCelebrated = movementMinutes >= movementGoal && movementGoal > 0;
    });
    await _updateWidget(_glassesToday, _dailyGoal);
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
    final storedNutritionGoals = _withDefaultNutritionGoals(
      await _storageService.getNutritionGoals(),
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
      weeklyData.add(storedGlassesToday);
      await _storageService.saveWeeklyData(weeklyData);
      final nutritionWeeklyData = List<int>.from(
        await _storageService.getNutritionWeeklyData(),
      );
      nutritionWeeklyData.removeAt(0);
      nutritionWeeklyData.add(
        _nutritionCompletedCount(storedNutritionToday, goals: storedNutritionGoals),
      );
      await _storageService.saveNutritionWeeklyData(nutritionWeeklyData);
      await _storageService.saveNutritionYesterday(storedNutritionToday);
      await _storageService.saveNutritionToday(_emptyNutritionValues());
      await _storageService.saveGlassesYesterday(storedGlassesToday);
      await _storageService.saveGlassesToday(0);
      await _storageService.clearLastDrinkAt();

      // Movement reset at midnight
      final storedMovementMinutes = await _storageService.getMovementMinutes();
      final movementWeeklyData = List<int>.from(await _storageService.getMovementWeeklyData());
      movementWeeklyData.removeAt(0);
      movementWeeklyData.add(storedMovementMinutes);
      await _storageService.saveMovementWeeklyData(movementWeeklyData);
      await _storageService.saveMovementYesterday(storedMovementMinutes);
      await _storageService.saveMovementMinutes(0);
      await _storageService.saveMovementSteps(0);

      await _storageService.saveLastReset(now);
    }
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
    setState(() {
      _glassesToday++;
      _dropTrigger = !_dropTrigger;
      _now = DateTime.now();
      _lastDrinkAt = _now;
      _refreshHydrationAdvice();
    });
    _storageService.saveGlassesToday(_glassesToday);
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

    setState(() {
      _glassesToday--;
      _now = DateTime.now();
      if (_glassesToday < _dailyGoal) {
        _goalCelebrated = false;
      }
      if (_glassesToday < _upperHydrationLimit) {
        _tooMuchWaterWarned = false;
      }
      if (_glassesToday == 0) {
        _lastDrinkAt = null;
      }
      _refreshHydrationAdvice();
    });

    await _storageService.saveGlassesToday(_glassesToday);
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: AppTheme.primaryAqua,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '5 días',
                        style: TextStyle(
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
                  position < 0.5
                      ? 'Agua'
                      : position < 1.5
                          ? 'Nutrición'
                          : 'Actividad',
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
              IconButton(
                icon: const Icon(Icons.calendar_today_rounded, size: 20),
                color: AppTheme.onSurfaceVariant,
                onPressed: () {},
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryAqua,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Color(0xFF00354A),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceVariant),
                onSelected: (value) {
                  if (value == 'info') {
                    _showFriendlyMessage(
                      title: _pagePosition.value < 0.5
                          ? 'Consejo de hidratación'
                          : _pagePosition.value < 1.5
                              ? 'Consejo de nutrición'
                              : 'Consejo de movimiento',
                      message: _pagePosition.value < 0.5
                          ? '¡Vas increíble! Bebe agua de a poco durante el día y tu cuerpo te lo va a aplaudir. 👏'
                          : _pagePosition.value < 1.5
                              ? 'Suma hábitos simples y amables: una fruta, una infusión o un snack saludable. Sin culpa, paso a paso. 🍎'
                              : 'Camina y muévete para activar tu cuerpo. 30 minutos al día equivalen a unos 3,000 pasos activos. ¡Tú puedes! 🏃‍♂️',
                      icon: Icons.info_outline_rounded,
                      color: _activeAccentColor,
                    );
                    return;
                  }

                  if (value == 'settings') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SetupScreen(
                          skipAutoRedirect: true,
                        ),
                      ),
                    );
                  }

                  if (value == 'movement_goal') {
                    _showMovementGoalSheet();
                    return;
                  }

                  if (value == 'logout') {
                    FirebaseAuth.instance.signOut();
                    StorageService().clearAll();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const InicioScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Información'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (_pagePosition.value >= 1.5)
                    const PopupMenuItem<String>(
                      value: 'movement_goal',
                      child: ListTile(
                        leading: Icon(Icons.edit_road_rounded),
                        title: Text('Meta de caminata'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Configuración'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Cerrar sesión'),
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
                    RepaintBoundary(child: _buildMovementPage(context)),
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
            // Teaser Card
            InkWell(
              onTap: () => _onSectionSelected(1),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.secondaryCoral.withValues(alpha: 0.20),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: AppTheme.secondaryCoral,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Buscas variedad de sabor?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Suma agua celular con cítricos e infusiones',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.primaryAqua,
                      size: 18,
                    ),
                  ],
                ),
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
    if (_pagePosition.value <= 1.0) {
      return Color.lerp(
        AppTheme.primaryBlue,
        const Color(0xFF7CB342),
        _pagePosition.value,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFF7CB342),
        const Color(0xFFE65100),
        (_pagePosition.value - 1.0).clamp(0.0, 1.0),
      )!;
    }
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
    setState(() {
      _nutritionToday = Map<String, int>.from(_nutritionToday)
        ..[habit.id] = (_nutritionToday[habit.id] ?? 0) + 1;
    });
    _storageService.saveNutritionToday(_nutritionToday);

    final goal = _nutritionGoals[habit.id] ?? habit.defaultGoal;
    final count = _nutritionToday[habit.id] ?? 0;
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objetivos saludables',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ajusta metas simples para tu día. Sin calorías ni presión.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton.filledTonal(
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
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: value < 8
                                ? () => setSheetState(() => draftGoals[habit.id] = value + 1)
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _nutritionGoals = _withDefaultNutritionGoals(draftGoals));
                        _storageService.saveNutritionGoals(_nutritionGoals);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Guardar objetivos'),
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

  Widget _buildNutritionAssistant(BuildContext context) {
    final pending = nutritionHabits.where((habit) {
      final count = _nutritionToday[habit.id] ?? 0;
      final goal = _nutritionGoals[habit.id] ?? habit.defaultGoal;
      return count < goal;
    }).toList();
    final message = pending.isEmpty
        ? '✨ Buen equilibrio hasta ahora. Tu día ya tiene hábitos suaves y completos.'
        : '${pending.first.emoji} ${_assistantMessageFor(pending.first)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(icon: Icons.auto_awesome, title: 'Asistente inteligente'),
        const SizedBox(height: 14),
        _StatusChip(label: '${(_nutritionProgress * 100).round()}% de equilibrio diario'),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.96),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tip liviano: elige una opción simple cuando te quede cómodo. No hace falta hacerlo perfecto.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
        ),
      ],
    );
  }

  String _assistantMessageFor(NutritionHabit habit) {
    return switch (habit.id) {
      'fruit' => 'Hace rato no registras fruta hoy. Una fruta puede sumar frescura.',
      'yogurt' => 'Un yogurt o lácteo puede ser una buena opción tranquila.',
      'tea' => 'Hora ideal para una infusión calentita o fresca.',
      _ => 'Un snack saludable puede acompañar tu día con calma.',
    };
  }

  Widget _buildNutritionYesterday(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(icon: Icons.history_rounded, title: 'Ayer'),
        const SizedBox(height: 14),
        ...nutritionHabits.map((habit) {
          final count = _nutritionYesterday[habit.id] ?? 0;
          final goal = _nutritionGoals[habit.id] ?? habit.defaultGoal;
          final done = count >= goal && goal > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${habit.emoji} ${habit.label}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$count/$goal',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _mlFromGlasses(int glasses) =>
      (glasses * AppConstants.waterStep).toDouble();

  double _percent(num value, num total) {
    if (total <= 0) {
      return 0;
    }
    return (value / total).clamp(0, 1).toDouble();
  }

  String get _feedbackMessage {
    if (_hydrationAdvice == null) {
      return 'Configura una meta para ver tu progreso.';
    }

    return switch (_hydrationAdvice!.status) {
      HydrationStatus.onTrack => 'Vas bien 💧',
      HydrationStatus.slightlyBehind =>
        'Te estás quedando, tomá un poco ahora.',
      HydrationStatus.behind =>
        'Te estás quedando, subamos el ritmo con calma.',
      HydrationStatus.critical =>
        'Te queda mucha agua en poco tiempo. Evitá tomar todo junto.',
    };
  }

  // Si vamos al día con el asistente la gota está feliz y con color.
  // Si vamos atrasados, la mostramos triste y en gris.
  HydrationPetMood get _petMood {
    final status = _hydrationAdvice?.status;
    final isOnTrack = status == null || status == HydrationStatus.onTrack;
    return isOnTrack ? HydrationPetMood.happy : HydrationPetMood.tired;
  }

  NutritionPetMood get _nutritionPetMood {
    final hour = DateTime.now().hour;
    final progress = _nutritionProgress;

    // Antes de las 12 (mañana): Feliz si ya empezó con algo
    if (hour < 12) {
      return progress > 0 ? NutritionPetMood.happy : NutritionPetMood.normal;
    }
    // Entre 12 y 20 (tarde): Feliz si va a mitad de camino
    if (hour < 20) {
      return progress >= 0.4 ? NutritionPetMood.happy : NutritionPetMood.normal;
    }
    // Después de las 20 (noche): Triste si no cumplió la meta
    return progress >= 0.8 ? NutritionPetMood.happy : NutritionPetMood.tired;
  }

  Future<void> _checkHealthConnectAvailability() async {
    final available = await HealthService.instance.isAvailable();
    if (!mounted) return;
    setState(() {
      _healthConnectAvailable = available;
    });
  }

  Future<void> _linkHealthConnect() async {
    final success = await HealthService.instance.requestPermissions();
    if (success) {
      setState(() {
        _healthConnectLinked = true;
      });
      await _storageService.saveHealthConnectLinked(true);
      await _fetchHealthConnectData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se otorgaron los permisos de Conexión de Salud. Puedes registrar manualmente.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _fetchHealthConnectData() async {
    if (!_healthConnectLinked) return;
    final data = await HealthService.instance.fetchTodayData();
    final steps = data['steps'] ?? 0;
    final minutes = data['minutes'] ?? 0;

    final currentMinutes = await _storageService.getMovementMinutes();
    final currentSteps = await _storageService.getMovementSteps();

    if (minutes > currentMinutes || steps > currentSteps) {
      final oldMinutes = _movementMinutesToday;
      setState(() {
        if (minutes > currentMinutes) _movementMinutesToday = minutes;
        if (steps > currentSteps) _movementStepsToday = steps;
      });
      await _storageService.saveMovementMinutes(_movementMinutesToday);
      await _storageService.saveMovementSteps(_movementStepsToday);
      _checkMovementGoalReached(oldMinutes, _movementMinutesToday);
    }
  }

  void _incrementMovementMinutes(int delta) async {
    final oldMinutes = _movementMinutesToday;
    setState(() {
      _movementMinutesToday += delta;
    });
    await _storageService.saveMovementMinutes(_movementMinutesToday);
    _checkMovementGoalReached(oldMinutes, _movementMinutesToday);
  }

  void _decrementMovementMinutes(int delta) async {
    if (_movementMinutesToday <= 0) return;
    setState(() {
      _movementMinutesToday = max(0, _movementMinutesToday - delta);
      if (_movementMinutesToday < _movementGoal) {
        _movementCelebrated = false;
      }
    });
    await _storageService.saveMovementMinutes(_movementMinutesToday);
  }

  void _incrementMovementSteps(int delta) async {
    setState(() {
      _movementStepsToday += delta;
    });
    await _storageService.saveMovementSteps(_movementStepsToday);
  }

  void _checkMovementGoalReached(int oldMinutes, int newMinutes) async {
    if (newMinutes >= _movementGoal && oldMinutes < _movementGoal && !_movementCelebrated) {
      setState(() {
        _movementCelebrated = true;
      });
      
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      if (!_movementHistory.contains(todayStr)) {
        _movementHistory.add(todayStr);
        await _storageService.saveMovementHistory(_movementHistory);
      }

      _confettiController.play();
      _showFriendlyMessage(
        title: '¡Meta alcanzada! 🌟',
        message: 'Completaste tus $_movementGoal minutos de movimiento hoy. Tu cuerpo y tu mente te lo agradecen. ¡A mantener la racha!',
        icon: Icons.celebration_rounded,
        color: const Color(0xFFE65100),
      );
    }
  }

  int _calculateStreak() {
    if (_movementHistory.isEmpty) return 0;
    
    final sortedDates = List<String>.from(_movementHistory)..sort();
    int streak = 0;
    DateTime checkDate = DateTime.now();
    final todayStr = checkDate.toIso8601String().split('T')[0];
    final yesterdayStr = checkDate.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    
    if (!sortedDates.contains(todayStr) && !sortedDates.contains(yesterdayStr)) {
      return 0;
    }
    
    if (sortedDates.contains(todayStr)) {
      checkDate = DateTime.now();
    } else {
      checkDate = DateTime.now().subtract(const Duration(days: 1));
    }
    
    while (true) {
      final dateStr = checkDate.toIso8601String().split('T')[0];
      if (sortedDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  void _showMovementGoalSheet() {
    int tempGoal = _movementGoal;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meta de movimiento diario',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ajusta tu meta diaria en minutos activos de caminata.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: tempGoal > 5
                            ? () => setSheetState(() => tempGoal -= 5)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Container(
                        width: 100,
                        alignment: Alignment.center,
                        child: Text(
                          '$tempGoal min',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: tempGoal < 180
                            ? () => setSheetState(() => tempGoal += 5)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _movementGoal = tempGoal;
                          _movementCelebrated = _movementMinutesToday >= _movementGoal;
                        });
                        _storageService.saveMovementGoal(tempGoal);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Guardar meta'),
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

  Widget _buildMovementPage(BuildContext context) {
    final streak = _calculateStreak();
    final activeMood = _movementMinutesToday >= _movementGoal
        ? MovementPetMood.happy
        : _movementMinutesToday > 0
            ? MovementPetMood.walking
            : MovementPetMood.bored;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            RepaintBoundary(
              child: MovementPet(
                mood: activeMood,
                size: 112,
              ),
            ),
            const SizedBox(height: 24),
            if (!_healthConnectLinked && _healthConnectAvailable) ...[
              _GradientInfoCard(
                colors: const [Color(0xFFFFB74D), Color(0xFFE65100)],
                shadowColor: const Color(0xFFE65100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sincroniza tu tiempo de actividad',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Para que no tengas que activar un cronómetro cada vez que caminas o te mueves, nos conectamos de forma segura con Conexión de Salud (Google Health Connect). Así, tu teléfono medirá tu tiempo activo en segundo plano de manera ultra eficiente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _linkHealthConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE65100),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Vincular con Conexión de Salud',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _healthConnectLinked = false;
                          _healthConnectAvailable = false;
                        });
                      },
                      child: const Text(
                        'O continuar con registro manual',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              MovementTrackerCard(
                currentMinutes: _movementMinutesToday,
                goalMinutes: _movementGoal,
                onAddMinutes: () => _incrementMovementMinutes(5),
                onAdd15Minutes: () => _incrementMovementMinutes(15),
                onRemoveMinutes: () => _decrementMovementMinutes(5),
                showManualControls: true,
              ),
              const SizedBox(height: 18),
              _GradientInfoCard(
                colors: const [Color(0xFFFFB74D), Color(0xFFE65100)],
                shadowColor: const Color(0xFFE65100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle(icon: Icons.insights_rounded, title: 'Resumen de actividad'),
                    const SizedBox(height: 16),
                    _StatusChip(label: 'Racha actual: $streak días 🔥'),
                    const SizedBox(height: 16),
                    Text(
                      'Tiempo activo hoy: $_movementMinutesToday min\n'
                      'Meta diaria: $_movementGoal min\n'
                      'Calorías activas estimadas: ${(_movementMinutesToday * 4.5).round()} kcal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conexión de Salud:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _StatusChip(
                          label: _healthConnectLinked ? '🟢 Conectado' : '⚪ Manual',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GradientInfoCard(
                colors: const [Color(0xFFFFCC80), Color(0xFFFFB74D)],
                shadowColor: const Color(0xFFFFB74D),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle(icon: Icons.military_tech_rounded, title: 'Logros y Medallas'),
                    const SizedBox(height: 16),
                    _buildMedalRow(
                      title: 'Caminante Constante',
                      subtitle: '3 días seguidos cumpliendo la meta',
                      icon: '🎖️',
                      unlocked: streak >= 3,
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _buildMedalRow(
                      title: 'Hábito de Hierro',
                      subtitle: '7 días seguidos cumpliendo la meta',
                      icon: '🏆',
                      unlocked: streak >= 7,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                child: WeeklyChart(
                  data: _movementWeeklyData,
                  gradientColors: const [Color(0xFFFFB74D), Color(0xFFE65100)],
                  shadowColor: const Color(0xFFE65100),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedalRow({
    required String title,
    required String subtitle,
    required String icon,
    required bool unlocked,
  }) {
    return Row(
      children: [
        Opacity(
          opacity: unlocked ? 1.0 : 0.25,
          child: Text(icon, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: unlocked ? 1.0 : 0.6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: unlocked ? null : TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: unlocked ? 0.85 : 0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Icon(
          unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          color: unlocked ? Colors.white : Colors.white30,
        ),
      ],
    );
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
    final movementColors = isDark
        ? const [Color(0xFF2C1607), Color(0xFF5A2A0C), Color(0xFF783E0E)]
        : const [Color(0xFFFFF4EB), Color(0xFFFFE3CC), Colors.white];

    List<Color> currentColors;
    if (pagePosition <= 1.0) {
      currentColors = List.generate(
        waterColors.length,
        (index) => Color.lerp(
          waterColors[index],
          nutritionColors[index],
          pagePosition.clamp(0.0, 1.0),
        )!,
      );
    } else {
      currentColors = List.generate(
        nutritionColors.length,
        (index) => Color.lerp(
          nutritionColors[index],
          movementColors[index],
          (pagePosition - 1.0).clamp(0.0, 1.0),
        )!,
      );
    }

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
              label: 'Frutas & Tés',
              icon: Icons.eco_rounded,
              selected: pagePosition >= 0.5 && pagePosition < 1.5,
              activeColor: AppTheme.secondaryCoral,
              onTap: () => onSectionSelected(1),
            ),
          ),
          Expanded(
            child: _PillItem(
              label: 'Actividad',
              icon: Icons.directions_walk_rounded,
              selected: pagePosition >= 1.5,
              activeColor: AppTheme.tertiaryMint,
              onTap: () => onSectionSelected(2),
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

class _GradientInfoCard extends StatelessWidget {
  const _GradientInfoCard({
    required this.colors,
    required this.shadowColor,
    required this.child,
  });

  final List<Color> colors;
  final Color shadowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _YesterdayWater extends StatelessWidget {
  const _YesterdayWater({required this.glassesYesterday});

  final int glassesYesterday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ayer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Text(
            key: ValueKey(glassesYesterday),
            '$glassesYesterday vasos',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
