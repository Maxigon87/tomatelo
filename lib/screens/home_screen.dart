import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tomatelo/models/nutrition_habit.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/screens/inicio_screen.dart';
import 'package:tomatelo/services/hydration_engine.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/utils/constants.dart';
import 'package:tomatelo/widgets/droplet_animation.dart';
import 'package:tomatelo/widgets/friendly_message.dart';
import 'package:tomatelo/widgets/hydration_pet.dart';
import 'package:tomatelo/widgets/nutrition_pet.dart';
import 'package:tomatelo/widgets/nutrition_tracker_card.dart';
import 'package:tomatelo/widgets/water_tracker_card.dart';
import 'package:tomatelo/widgets/weekly_chart.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hydrationRefresh = const Duration(minutes: 1);
    _pagePosition = ValueNotifier<double>(0);
    _pageController.addListener(_handlePageScroll);
    _initializeScreen();
    _startAdvisorRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController
      ..removeListener(_handlePageScroll)
      ..dispose();
    _pagePosition.dispose();
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
    });
    await _updateWidget(_glassesToday, _dailyGoal);
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
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

                  if (value == 'settings') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SetupScreen(
                          skipAutoRedirect: true,
                        ),
                      ),
                    );
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
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Información'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Configuración'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Cerrar sesión'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
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
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  height: kToolbarHeight,
                  child: Center(
                    child: _SectionPill(pagePosition: position),
                  ),
                ),
                DropletAnimation(trigger: _dropTrigger),
                if (_friendlyMessage != null) _friendlyMessage!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterPage(BuildContext context) {
    return SingleChildScrollView(
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
            RepaintBoundary(child: HydrationPet(mood: _petMood, size: 112)),
            const SizedBox(height: 24),
            WaterTrackerCard(
              currentGlasses: _glassesToday,
              goalGlasses: _dailyGoal,
              onAddWater: _incrementGlasses,
              onRemoveWater: _decrementGlasses,
            ),
            const SizedBox(height: 12),
            if (_hydrationAdvice != null)
              Text(
                _feedbackMessage,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            if (_reminderSuggestion != null) ...[
              const SizedBox(height: 6),
              Text(
                'Siguiente sugerencia: ${_reminderSuggestion!.minutesUntilNextReminder} min (${_formatTime(_reminderSuggestion!.suggestedAt)})',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            if (_dailyGoal > 0)
              Text(
                'Meta: $_dailyGoal vasos · Límite sugerido: $_upperHydrationLimit',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 18),
            if (_hydrationAdvice != null) ...[
              _GradientInfoCard(
                colors: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                shadowColor: const Color(0xFF2F80ED),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle(icon: Icons.auto_awesome, title: 'Asistente inteligente'),
                    const SizedBox(height: 16),
                    Text(
                      'Actual: ${_mlFromGlasses(_glassesToday).round()} ml · Ideal: ${_hydrationAdvice!.idealMl.round()} ml',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _percent(_mlFromGlasses(_glassesToday), _dailyGoal * AppConstants.waterStep),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      backgroundColor: Colors.black.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _percent(_hydrationAdvice!.idealMl, _dailyGoal * AppConstants.waterStep),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.6),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 16),
                    _StatusChip(label: 'Estado: ${_hydrationAdvice!.status.value}'),
                    const SizedBox(height: 10),
                    Text(_hydrationAdvice!.message, style: TextStyle(color: Colors.white.withValues(alpha: 0.95))),
                    const SizedBox(height: 12),
                    Text(
                      'Tomá ahora: ${_hydrationAdvice!.recommendedMlNow.round()} ml · cada ${_hydrationAdvice!.recommendedIntervalMinutes} min',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    if (_hydrationAdvice!.unsafeToCatchUp) ...[
                      const SizedBox(height: 10),
                      Text(
                        _hydrationAdvice!.warning ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFFF8A80), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _GradientInfoCard(
              colors: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
              shadowColor: const Color(0xFF2F80ED),
              child: _YesterdayWater(glassesYesterday: _glassesYesterday),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: WeeklyChart(
                data: _weeklyData,
                gradientColors: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                shadowColor: const Color(0xFF2F80ED),
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
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            RepaintBoundary(
              child: NutritionPet(
                mood: _nutritionPetMood,
                progress: _nutritionProgress,
                size: 112,
              ),
            ),
            const SizedBox(height: 24),
            NutritionTrackerCard(
              today: _nutritionToday,
              goals: _nutritionGoals,
              completed: _nutritionCompleted,
              totalGoal: _nutritionGoalTotal,
              onAddHabit: _incrementNutritionHabit,
              onOpenGoals: _showNutritionGoalsSheet,
            ),
            const SizedBox(height: 18),
            _GradientInfoCard(
              colors: const [Color(0xFF8BC34A), Color(0xFFFFB74D)],
              shadowColor: const Color(0xFFFFB74D),
              child: _buildNutritionAssistant(context),
            ),
            const SizedBox(height: 16),
            _GradientInfoCard(
              colors: const [Color(0xFFAED581), Color(0xFFFFCC80)],
              shadowColor: const Color(0xFFFFB74D),
              child: _buildNutritionYesterday(context),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: WeeklyChart(
                data: _nutritionWeeklyData,
                gradientColors: const [Color(0xFF8BC34A), Color(0xFF7CB342)],
                shadowColor: const Color(0xFF7CB342),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color get _activeAccentColor => Color.lerp(
        AppTheme.primaryBlue,
        const Color(0xFF7CB342),
        _pagePosition.value,
      )!;

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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pagePosition <= 0 ? waterColors : 
                  pagePosition >= 1 ? nutritionColors : 
                  List.generate(
                    waterColors.length,
                    (index) => Color.lerp(
                      waterColors[index],
                      nutritionColors[index],
                      pagePosition,
                    )!,
                  ),
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Opacity(
                opacity: (1 - pagePosition).clamp(0, 1),
                child: AnimatedBubbles(isActive: pagePosition < 0.99),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: Opacity(
                opacity: pagePosition.clamp(0, 1),
                child: NutritionParticles(isActive: pagePosition > 0.01),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({required this.pagePosition});

  final double pagePosition;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillItem(label: '💧 Agua', selected: pagePosition < 0.5),
            const SizedBox(width: 6),
            _PillItem(label: '🍎 Nutrición', selected: pagePosition >= 0.5),
          ],
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF2F80ED) : Colors.black54,
          fontWeight: FontWeight.w800,
          fontSize: 12,
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
