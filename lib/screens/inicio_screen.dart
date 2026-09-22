import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/widgets/tomatelo_logo.dart';

/// Screen 2: Iniciar Sesión / Registro - TOMÁTELO (Stitch Design System)
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storageService = StorageService();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isEmailValid = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounceScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutBack),
    );
    _loadRememberedEmail();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _passwordController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final text = _emailController.text.trim();
    final isValid = text.contains('@') && text.contains('.');
    if (isValid != _isEmailValid) {
      setState(() {
        _isEmailValid = isValid;
      });
    }
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('remembered_email');
      if (email != null && email.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _emailController.text = email;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  void _triggerMascotBounce() {
    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  Future<void> _handleAuthSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    _triggerMascotBounce();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        // Firebase Auth SignIn
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Firebase Auth Create User
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Handle remember me
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', email);
      } else {
        await prefs.remove('remembered_email');
      }

      // Sync user data with Firestore
      await _storageService.syncFromFirestore();

      final userData = await _storageService.getUserData();
      final dailyGoal = await _storageService.getDailyGoal();
      final needsSetup = userData == null || dailyGoal == 0;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: AppTheme.primaryAqua),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isLoginMode
                      ? '¡Sesión iniciada con éxito! A hidratarse 💧'
                      : '¡Cuenta creada con éxito! Bienvenido 🌱',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => needsSetup ? const SetupScreen() : const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final errorMessage = _getAuthErrorMessage(e.code);
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'No encontramos una cuenta con ese correo electrónico.',
      'wrong-password' => 'La contraseña ingresada es incorrecta.',
      'invalid-email' => 'El formato del correo electrónico no es válido.',
      'email-already-in-use' => 'Ya existe una cuenta vinculada a este correo.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada temporalmente.',
      'too-many-requests' => 'Demasiados intentos fallidos. Intenta más tarde.',
      'network-request-failed' => 'Error de conexión. Revisa tu red a internet.',
      _ => 'Error de autenticación ($code). Verifique sus credenciales.',
    };
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.secondaryCoral),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppTheme.primaryAqua),
              SizedBox(width: 10),
              Text(
                'Recuperar contraseña',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace oficial de restablecimiento.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'tu@correo.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppTheme.primaryAqua),
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAqua,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                if (!resetFormKey.currentState!.validate()) return;
                final emailToSend = resetEmailController.text.trim();
                Navigator.of(dialogContext).pop();
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: emailToSend);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Enlace enviado a $emailToSend. Revisa tu bandeja de entrada.'),
                      backgroundColor: AppTheme.surfaceHigh,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  _showErrorSnackBar('No se pudo enviar el correo de recuperación.');
                }
              },
              child: const Text('Enviar enlace', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Dynamic Ambient Liquid Background Orbs (Stitch Design System)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryAqua.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryAqua.withValues(alpha: 0.15),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryCoral.withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryCoral.withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryMint.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.tertiaryMint.withValues(alpha: 0.10),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // Main Scrollable Area
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Header & Mascot Hero
                    GestureDetector(
                      onTap: _triggerMascotBounce,
                      child: ScaleTransition(
                        scale: _bounceScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glass Pod Orb Container
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surfaceHigh.withValues(alpha: 0.85),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: TomateloLogo(size: 84),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Typography Header (Stitch Design Token)
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.white,
                          AppTheme.primaryAquaDim,
                          AppTheme.primaryAqua,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'TOMÁTELO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tu dosis diaria de hidratación consciente\ny vitalidad fresca',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Glass Form Card Container
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 380),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLow.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Tabs / Indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isLoginMode ? 'Iniciar Sesión' : 'Crear Cuenta',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHigh,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _isLoginMode ? 'Acceso Seguro' : 'Paso 1 de 2',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryAqua,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Field: Email
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.water_drop_rounded,
                                      size: 15,
                                      color: AppTheme.primaryAqua,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Correo electrónico',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _isEmailValid ? 1.0 : 0.0,
                                  child: const Text(
                                    'Válido',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.tertiaryMint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'tu@correo.com',
                                hintStyle: TextStyle(
                                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceContainer,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppTheme.primaryAqua, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!value.contains('@')) {
                                  return 'Correo no válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Field: Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 15,
                                      color: AppTheme.secondaryCoral,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Contraseña',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isLoginMode)
                                  GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: const Text(
                                      '¿Olvidaste tu clave?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryAqua,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••••••',
                                hintStyle: TextStyle(
                                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    size: 20,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceContainer,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppTheme.primaryAqua, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                if (value.length < 6) {
                                  return 'Mínimo 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Remember me checkbox
                            if (_isLoginMode)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppTheme.primaryAqua,
                                      checkColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recordar correo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            // Primary CTA Button: Ingresar a mi ritmo
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryAqua,
                                      AppTheme.primaryAquaDim,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryAqua.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleAuthSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isLoginMode
                                                  ? 'Ingresar a mi ritmo'
                                                  : 'Comenzar mi ritmo',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Account Switcher Footer
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLoginMode
                                        ? '¿Primera vez en Tomátelo? '
                                        : '¿Ya tienes cuenta? ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isLoginMode = !_isLoginMode;
                                      });
                                    },
                                    child: Text(
                                      _isLoginMode ? 'Crear una cuenta' : 'Iniciar sesión',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryAqua,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Debug Mode Bypass Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const HomeScreen(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryAqua,
                                  side: BorderSide(
                                    color: AppTheme.primaryAqua.withValues(alpha: 0.35),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                                icon: const Icon(Icons.bug_report_rounded, size: 18),
                                label: const Text(
                                  'Entrar (Debug)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Privacy & Encryption Security Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLowest.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: AppTheme.tertiaryMint,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tus registros de salud se cifran en tu dispositivo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
