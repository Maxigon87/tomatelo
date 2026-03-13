import 'package:flutter/material.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/widgets/water_progress.dart';
import 'package:tomatelo/widgets/water_button.dart';
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
      final weeklyData = await _storageService.getWeeklyData();
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
    });
    _storageService.saveGlassesToday(_glassesToday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomatelo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffFF6B6B),
              Color(0xffFF8E53),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              const Image(
                image: AssetImage('assets/images/logo.png'),
                height: 120,
              ),

              const SizedBox(height: 30),

              WaterProgress(current: _glassesToday, total: _dailyGoal),

              const SizedBox(height: 40),

              WaterButton(onPressed: _incrementGlasses),

              const SizedBox(height: 50),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "Yesterday",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "$_glassesYesterday glasses",
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              WeeklyChart(data: _weeklyData),
            ],
          ),
        ),
      ),
    ));
  }
}
