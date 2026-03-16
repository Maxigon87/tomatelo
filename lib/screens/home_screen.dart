import 'package:flutter/material.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/widgets/droplet_animation.dart';
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
  int _glassesToday = 0;
  int _glassesYesterday = 0;
  int _dailyGoal = 0;
  List<int> _weeklyData = List.filled(7, 0);
  bool _dropTrigger = false;
  bool _goalCelebrated = false;
  bool _tooMuchWaterWarned = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _resetDataAtMidnight();
  }

  Future<void> _loadData() async {
    final glassesToday = await _storageService.getGlassesToday();
    final glassesYesterday = await _storageService.getGlassesYesterday();
    final dailyGoal = await _storageService.getDailyGoal();
    final weeklyData = await _storageService.getWeeklyData();
    setState(() {
      _glassesToday = glassesToday;
      _glassesYesterday = glassesYesterday;
      _dailyGoal = dailyGoal;
      _weeklyData = weeklyData;
      _goalCelebrated = glassesToday >= dailyGoal && dailyGoal > 0;
      _tooMuchWaterWarned = false;
    });
  }

  Future<void> _resetDataAtMidnight() async {
    final lastReset = await _storageService.getLastReset();
    final now = DateTime.now();
    if (lastReset != null &&
        (now.day != lastReset.day ||
            now.month != lastReset.month ||
            now.year != lastReset.year)) {
      final weeklyData = List<int>.from(await _storageService.getWeeklyData());
      weeklyData.removeAt(0);
      weeklyData.add(_glassesToday);
      await _storageService.saveWeeklyData(weeklyData);
      await _storageService.saveGlassesYesterday(_glassesToday);
      await _storageService.saveGlassesToday(0);
      await _storageService.saveLastReset(now);
      _loadData();
    }
  }

  int get _upperHydrationLimit {
    if (_dailyGoal <= 0) {
      return 0;
    }
    return _dailyGoal + 3;
  }

  void _showFriendlyAlert({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Genial!'),
          ),
        ],
      ),
    );
  }

  void _incrementGlasses() {
    setState(() {
      _glassesToday++;
      _dropTrigger = !_dropTrigger;
    });
    _storageService.saveGlassesToday(_glassesToday);

    if (_dailyGoal > 0 && _glassesToday >= _dailyGoal && !_goalCelebrated) {
      _goalCelebrated = true;
      _showFriendlyAlert(
        title: '¡Meta cumplida! 🎉',
        message:
            '¡Excelente! Ya llegaste a tu objetivo de hoy. Ahora mantén un ritmo tranqui y escucha a tu cuerpo. 💧',
      );
    }

    if (_upperHydrationLimit > 0 &&
        _glassesToday >= _upperHydrationLimit &&
        !_tooMuchWaterWarned) {
      _tooMuchWaterWarned = true;
      _showFriendlyAlert(
        title: 'Ojo, súper hidratado 😅',
        message:
            'Ya vas $_glassesToday vasos (límite sugerido: $_upperHydrationLimit). Mejor bajemos el ritmo para no pasarnos con el agua hoy.',
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
            icon: Image.asset('assets/images/logo.gif', width: 28, height: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: const Text('Consejo de hidratación'),
                  content: const Text(
                    '¡Vas increíble! Bebe agua de a poco durante el día y tu cuerpo te lo va a aplaudir. 👏',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
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
                    const Image(
                      image: AssetImage('assets/images/icono.png'),
                      height: 110,
                    ),
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
                    if (_dailyGoal > 0)
                      Text(
                        'Meta: $_dailyGoal vasos · Límite sugerido: $_upperHydrationLimit',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 18),
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
          ],
        ),
      ),
    );
  }
}
