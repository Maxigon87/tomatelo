import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/screens/home_screen.dart';
import 'package:tomatelo/services/storage_service.dart';
import 'package:tomatelo/services/notification_service.dart';
import 'package:tomatelo/theme/app_theme.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  late final bool _useWaterTheme;

  @override
  void initState() {
    super.initState();
    _useWaterTheme = math.Random().nextBool();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('remembered_email');
      if (email != null && email.isNotEmpty) {
        setState(() {
          _loginEmailController.text = email;
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error loading remembered email: $e');
    }
  }

  Future<void> _handleRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe && _isLoginMode) {
        await prefs.setString('remembered_email', _loginEmailController.text.trim());
      } else {
        await prefs.remove('remembered_email');
      }
    } catch (e) {
      print('Error saving remembered email: $e');
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _loginEmailController.text);
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: Form(
            key: resetFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'usuario@correo.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (resetFormKey.currentState?.validate() ?? false) {
                  final email = resetEmailController.text.trim();
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Enviando correo de recuperación...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Enlace de recuperación enviado a: $email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    String errorMessage = 'No se pudo enviar el correo de recuperación.';
                    if (e.code == 'user-not-found') {
                      errorMessage = 'No existe ningún usuario registrado con este correo.';
                    } else if (e.code == 'invalid-email') {
                      errorMessage = 'El formato del correo es inválido.';
                    }
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCurrentForm() async {
    final activeForm = _isLoginMode ? _loginFormKey : _registerFormKey;
    if (!(activeForm.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _isLoginMode
        ? _loginEmailController.text.trim()
        : _registerEmailController.text.trim();
    final password = _isLoginMode
        ? _loginPasswordController.text
        : _registerPasswordController.text;

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _handleRememberMe();
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      final storage = StorageService();
      await storage.clearAll();
      await storage.syncFromFirestore();

      final userData = await storage.getUserData();
      final dailyGoal = await storage.getDailyGoal();

      if (!mounted) return;

      if (userData == null || dailyGoal == 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
      } else {
        await NotificationService.instance.scheduleHydrationReminder(
          minutes: userData.reminderMinutes,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocurrió un error en la autenticación.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No se encontró ningún usuario con este correo.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Este correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El formato del correo es inválido.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil (mínimo 6 caracteres).';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Las credenciales ingresadas son incorrectas.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final waterColors = isDark
        ? const [Color(0xFF071726), Color(0xFF0E3658), Color(0xFF164A73)]
        : const [Color(0xFFEFF8FF), Color(0xFFDDF2FF), Colors.white];
    final nutritionColors = isDark
        ? const [Color(0xFF101F13), Color(0xFF27451F), Color(0xFF5B3A16)]
        : const [Color(0xFFF4FFE8), Color(0xFFFFF2CC), Colors.white];

    final colors = _useWaterTheme ? waterColors : nutritionColors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _useWaterTheme
                  ? const AnimatedBubbles(isActive: true)
                  : const NutritionParticles(isActive: true),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Image(
                              image: AssetImage('assets/images/logo.png'),
                              height: 120,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isLoginMode
                                  ? 'Inicia sesión en Tomatelo'
                                  : 'Crea tu cuenta en Tomatelo',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLoginMode
                                  ? 'Accede con tu correo y contraseña'
                                  : 'Regístrate para empezar tu hábito',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            _ModeToggle(
                              isLoginMode: _isLoginMode,
                              onChanged: (isLogin) {
                                setState(() => _isLoginMode = isLogin);
                              },
                            ),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: _isLoginMode
                                  ? _AuthForm(
                                      key: const ValueKey('login_form'),
                                      formKey: _loginFormKey,
                                      emailController: _loginEmailController,
                                      passwordController: _loginPasswordController,
                                    )
                                  : _AuthForm(
                                      key: const ValueKey('register_form'),
                                      formKey: _registerFormKey,
                                      emailController: _registerEmailController,
                                      passwordController: _registerPasswordController,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            if (_isLoginMode) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() => _rememberMe = value ?? false);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Recuérdame',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF114B86),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF114B86),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitCurrentForm,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode
                                            ? 'Iniciar sesión'
                                            : 'Registrarme',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const _AuthForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    String? emailValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Ingresa tu correo';
      }
      if (!value.contains('@') || !value.contains('.')) {
        return 'Ingresa un correo válido';
      }
      return null;
    }

    String? passwordValidator(String? value) {
      if (value == null || value.isEmpty) {
        return 'Ingresa tu contraseña';
      }
      if (value.length < 6) {
        return 'Mínimo 6 caracteres';
      }
      return null;
    }

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Correo',
              hintText: 'usuario@correo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: emailValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: passwordValidator,
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isLoginMode;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isLoginMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ToggleButton(
            text: 'Iniciar sesión',
            selected: isLoginMode,
            onTap: () => onChanged(true),
          ),
          _ToggleButton(
            text: 'Registrarme',
            selected: !isLoginMode,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF114B86),
            ),
          ),
        ),
      ),
    );
  }
}
