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

  void _incrementGlasses() {
    setState(() {
      _glassesToday++;
      _dropTrigger = !_dropTrigger;
    });
    _storageService.saveGlassesToday(_glassesToday);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal == 0
        ? 0
        : ((_glassesToday / _dailyGoal) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomatelo'),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/icono.png',
            ), // Reemplaza con la ruta de tu imagen
            onPressed: () {
              // Agrega aquí la funcionalidad para tu nuevo icono
            },
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
                    'Bebe agua regularmente durante el día para mantener una buena hidratación.',
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    const Image(
                      image: AssetImage('assets/images/logo.png'),
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
                    const SizedBox(height: 30),
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
