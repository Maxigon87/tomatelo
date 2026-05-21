import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/theme/app_theme.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _isLoginMode = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  void _submitCurrentForm() {
    final activeForm = _isLoginMode ? _loginFormKey : _registerFormKey;
    if (activeForm.currentState?.validate() ?? false) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF125AAB),
                  AppTheme.primaryBlue,
                  const Color(0xFF1C9C8A),
                  const Color(0xFF4FD6B2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _FloatingDecorations(progress: _controller.value),
                  ),
                  Center(
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
                                          emailController:
                                              _loginEmailController,
                                          passwordController:
                                              _loginPasswordController,
                                        )
                                      : _AuthForm(
                                          key: const ValueKey('register_form'),
                                          formKey: _registerFormKey,
                                          emailController:
                                              _registerEmailController,
                                          passwordController:
                                              _registerPasswordController,
                                        ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitCurrentForm,
                                    child: Text(
                                      _isLoginMode
                                          ? 'Iniciar sesión'
                                          : 'Registrarme',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('test')
                                            .add({
                                          'message': 'Hola Firebase',
                                          'createdAt': Timestamp.now(),
                                        });
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('¡Dato enviado a Firestore! Checkea la consola.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        print('Dato enviado');
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        print('Error enviando dato: $e');
                                      }
                                    },
                                    icon: const Icon(Icons.cloud_upload),
                                    label: const Text('Enviar Test Firebase'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.black26,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
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
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo',
              hintText: 'usuario@correo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: emailValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded),
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

class _FloatingDecorations extends StatelessWidget {
  final double progress;

  const _FloatingDecorations({required this.progress});

  @override
  Widget build(BuildContext context) {
    final decorationItems = [
      _FloatItem('🧙', 0.08, 0.18, 20, 0.4),
      _FloatItem('🍅', 0.82, 0.20, 24, 1.5),
      _FloatItem('🍓', 0.18, 0.72, 22, 2.8),
      _FloatItem('🧙‍♀️', 0.78, 0.74, 20, 3.4),
      _FloatItem('🍐', 0.52, 0.16, 21, 4.2),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: decorationItems.map((item) {
            final dx = constraints.maxWidth * item.x +
                math.cos(progress * math.pi * 2 + item.phase) * 12;
            final dy = constraints.maxHeight * item.y +
                math.sin(progress * math.pi * 2 + item.phase) * 18;
            return Positioned(
              left: dx,
              top: dy,
              child: Opacity(
                opacity: 0.78,
                child: Text(
                  item.emoji,
                  style: TextStyle(fontSize: item.size),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FloatItem {
  final String emoji;
  final double x;
  final double y;
  final double size;
  final double phase;

  const _FloatItem(this.emoji, this.x, this.y, this.size, this.phase);
}
