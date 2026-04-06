import 'package:flutter/material.dart';
import 'package:tomatelo/services/hydration_engine.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/utils/constants.dart';
import 'package:tomatelo/widgets/droplet_animation.dart';
import 'package:tomatelo/widgets/friendly_message.dart';
import 'package:tomatelo/widgets/hydration_pet.dart';
import 'package:tomatelo/widgets/water_button.dart';
import 'package:tomatelo/widgets/water_progress.dart';
import 'package:tomatelo/widgets/weekly_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
  late final DateTime _dayStartTime;
  late final DateTime _dayEndTime;
  DateTime _now = DateTime.now();
  late final Duration _hydrationRefresh;
  Widget? _friendlyMessage;
  ReminderSuggestion? _reminderSuggestion;
  DateTime? _lastDrinkAt;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dayStartTime = DateTime(today.year, today.month, today.day, 8);
    _dayEndTime = DateTime(today.year, today.month, today.day, 22);
    _hydrationRefresh = const Duration(minutes: 1);
    _initializeScreen();
    _startAdvisorRefresh();
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
    await _resetDataAtMidnight();
    await _loadData();
  }

  Future<void> _loadData() async {
    final glassesToday = await _storageService.getGlassesToday();
    final glassesYesterday = await _storageService.getGlassesYesterday();
    final dailyGoal = await _storageService.getDailyGoal();
    final weeklyData = await _storageService.getWeeklyData();
    final lastDrinkAt = await _storageService.getLastDrinkAt();
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
      _refreshHydrationAdvice();
    });
  }

  Future<void> _resetDataAtMidnight() async {
    final lastReset = await _storageService.getLastReset();
    final now = DateTime.now();
    final storedGlassesToday = await _storageService.getGlassesToday();

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

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal == 0
        ? 0
        : (((_glassesToday > _dailyGoal ? _dailyGoal : _glassesToday) /
                      _dailyGoal) *
                  100)
              .round();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              _showFriendlyMessage(
                title: 'Consejo de hidratación',
                message:
                    '¡Vas increíble! Bebe agua de a poco durante el día y tu cuerpo te lo va a aplaudir. 👏',
                icon: Icons.info_outline_rounded,
                color: AppTheme.primaryBlue,
              );
            },
          ),
        ],
      ),
      body: WaterBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    HydrationPet(mood: _petMood, size: 112),
                    const SizedBox(height: 24),
                    WaterProgress(current: _glassesToday, total: _dailyGoal),
                    const SizedBox(height: 14),
                    Text(
                      '$progress% hidratado hoy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    WaterButton(onPressed: _incrementGlasses),
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asistente inteligente',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Actual: ${_mlFromGlasses(_glassesToday).round()} ml · Ideal: ${_hydrationAdvice!.idealMl.round()} ml',
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _percent(
                                  _mlFromGlasses(_glassesToday),
                                  _dailyGoal * AppConstants.waterStep,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _percent(
                                  _hydrationAdvice!.idealMl,
                                  _dailyGoal * AppConstants.waterStep,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.primaryBlue.withOpacity(0.55),
                                backgroundColor: AppTheme.primaryBlue
                                    .withOpacity(0.15),
                              ),
                              const SizedBox(height: 10),
                              Text('Estado: ${_hydrationAdvice!.status.value}'),
                              const SizedBox(height: 6),
                              Text(_hydrationAdvice!.message),
                              const SizedBox(height: 10),
                              Text(
                                'Tomá ahora: ${_hydrationAdvice!.recommendedMlNow.round()} ml · cada ${_hydrationAdvice!.recommendedIntervalMinutes} min',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (_hydrationAdvice!.unsafeToCatchUp) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _hydrationAdvice!.warning ?? '',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Ayer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: Text(
                                key: ValueKey(_glassesYesterday),
                                '$_glassesYesterday vasos',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 18,
                        ),
                        child: WeeklyChart(data: _weeklyData),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DropletAnimation(trigger: _dropTrigger),
            if (_friendlyMessage != null) _friendlyMessage!,
          ],
        ),
      ),
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
}
