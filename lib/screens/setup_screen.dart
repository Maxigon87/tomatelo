import 'package:flutter/material.dart';
import 'package:tomatelo/models/user_data.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/services/hydration_engine.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/utils/constants.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    this.skipAutoRedirect = false,
    this.isEmbeddedModal = false,
  });

  final bool skipAutoRedirect;
  final bool isEmbeddedModal;

  /// Método estático conveniente para mostrar la configuración en una hoja modal animada
  static Future<bool?> showModal(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          clipBehavior: Clip.antiAlias,
          child: const SetupScreen(
            skipAutoRedirect: true,
            isEmbeddedModal: true,
          ),
        ),
      ),
    );
  }

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');
  final _reminderController = TextEditingController(text: '60');
  final _storageService = StorageService();
  final _hydrationEngine = const HydrationEngine();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _liveCalculatedMl = 2450;
  int _liveCalculatedGlasses = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _loadSavedData();
    _redirectIfUserAlreadyConfigured();

    _weightController.addListener(_recalculateLiveGoal);
    _heightController.addListener(_recalculateLiveGoal);
  }

  @override
  void dispose() {
    _weightController.removeListener(_recalculateLiveGoal);
    _heightController.removeListener(_recalculateLiveGoal);
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _reminderController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final userData = await _storageService.getUserData();
    final reminderMinutes = await _storageService.getReminderMinutes();

    if (userData == null || !mounted) {
      _recalculateLiveGoal();
      return;
    }

    setState(() {
      _nameController.text = userData.name;
      _weightController.text = userData.weight.toStringAsFixed(
        userData.weight.truncateToDouble() == userData.weight ? 0 : 1,
      );
      _heightController.text = userData.height.toStringAsFixed(
        userData.height.truncateToDouble() == userData.height ? 0 : 1,
      );
      _reminderController.text = reminderMinutes.toString();
    });

    _recalculateLiveGoal();
  }

  void _recalculateLiveGoal() {
    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.')) ?? 0;

    if (weight > 0) {
      final ml = _hydrationEngine.calculateDailyGoalInMl(weight, height: height);
      final glasses = _hydrationEngine.calculateDailyGoalInGlasses(ml.toDouble(), AppConstants.waterStep);
      setState(() {
        _liveCalculatedMl = ml;
        _liveCalculatedGlasses = glasses;
      });
    }
  }

  Future<void> _redirectIfUserAlreadyConfigured() async {
    final userData = await _storageService.getUserData();
    final dailyGoal = await _storageService.getDailyGoal();
    if (widget.skipAutoRedirect || widget.isEmbeddedModal || userData == null || dailyGoal == 0 || !mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: const HomeScreen()),
      ),
    );
  }

  Future<void> _saveSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final weight = double.parse(_weightController.text.trim().replaceAll(',', '.'));
      final height = double.parse(_heightController.text.trim().replaceAll(',', '.'));
      final reminderMinutes = int.parse(_reminderController.text.trim());

      final userData = UserData(
        name: name,
        weight: weight,
        height: height,
        reminderMinutes: reminderMinutes,
      );

      await _storageService.saveUserData(userData);

      final dailyGoalInMl = _hydrationEngine.calculateDailyGoalInMl(weight, height: height);
      final dailyGoalInGlasses = _hydrationEngine.calculateDailyGoalInGlasses(
        dailyGoalInMl.toDouble(),
        AppConstants.waterStep,
      );

      await _storageService.saveDailyGoal(dailyGoalInGlasses);
      await _storageService.saveReminderMinutes(reminderMinutes);

      await NotificationService.instance.scheduleHydrationReminder(
        minutes: reminderMinutes,
      );

      await _storageService.saveLastReset(DateTime.now());

      if (!mounted) return;

      if (widget.isEmbeddedModal) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, animation, __) =>
                FadeTransition(opacity: animation, child: const HomeScreen()),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving configuration: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isEmbeddedModal)
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              // Encabezado
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAqua.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryAqua.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: AppTheme.primaryAqua,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración de Hidratación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cálculo personalizado según peso y altura',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isEmbeddedModal)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Tarjeta de Vista Previa de Cálculo en Tiempo Real
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryAqua.withValues(alpha: 0.18),
                      AppTheme.surfaceContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryAqua.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAqua.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryAqua,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF00354A),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meta Diaria Recomendada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_liveCalculatedMl ml / $_liveCalculatedGlasses vasos',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryAqua,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Calculado con 35ml/kg + ajuste de estatura',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Campo de Nombre
              _buildInputField(
                controller: _nameController,
                label: 'Tu nombre o apodo',
                hint: 'Ej. Mateo',
                icon: Icons.person_outline_rounded,
                isText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre para personalizar tu avatar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo de Peso
              _buildInputField(
                controller: _weightController,
                label: 'Peso corporal (kg)',
                hint: 'Ej. 70.5',
                icon: Icons.monitor_weight_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu peso';
                  }
                  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0 || parsed > 300) {
                    return 'Ingresa un peso válido en kg';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo de Altura
              _buildInputField(
                controller: _heightController,
                label: 'Altura (cm)',
                hint: 'Ej. 175',
                icon: Icons.height_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu altura';
                  }
                  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 50 || parsed > 250) {
                    return 'Ingresa una altura válida en cm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo de Recordatorio
              _buildInputField(
                controller: _reminderController,
                label: 'Frecuencia de Recordatorio (minutos)',
                hint: 'Ej. 60',
                icon: Icons.notifications_active_outlined,
                helperText: 'Recomendado 45 - 90 min. Mínimo 15 min.',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Configura el intervalo de recordatorio';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 15) {
                    return 'Mínimo 15 minutos entre avisos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón Principal Guardar y Sincronizar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAqua,
                  foregroundColor: const Color(0xFF00354A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                  shadowColor: AppTheme.primaryAqua.withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00354A)),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Guardar y Sincronizar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbeddedModal) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: WaterBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isText = false,
    String? helperText,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isText ? TextInputType.name : const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppTheme.primaryAqua, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceContainer,
            helperText: helperText,
            helperStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryAqua,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.secondaryCoral,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
