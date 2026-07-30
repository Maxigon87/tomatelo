import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:tomatelo/models/hydration_advice.dart';

class ReminderSuggestion {
  const ReminderSuggestion({
    required this.minutesUntilNextReminder,
    required this.suggestedAt,
    required this.reason,
  });

  final int minutesUntilNextReminder;
  final DateTime suggestedAt;
  final String reason;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelKey = 'hydration_reminders_water';
  static const String _waterDropSound = 'resource://raw/res_water_drop';
  static const int _reminderId = 1001;
  static const int _minReminderMinutes = 15;
  static const int _maxReminderMinutes = 120;

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Recordatorios de Mascotas Tomatelo',
        channelDescription: 'Notificaciones de tus guardianes de salud',
        defaultColor: const Color(0xFF00BCD4),
        importance: NotificationImportance.High,
        playSound: true,
        soundSource: _waterDropSound,
      ),
    ]);

    await AwesomeNotifications().isNotificationAllowed().then((
      isAllowed,
    ) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleHydrationReminder({
    required int minutes,
    String? customPetMessage,
  }) async {
    await cancelHydrationReminder();

    final safeMinutes = _sanitizeMinutes(minutes);
    final defaultMessages = <String>[
      '💧 ¡A Gota-Bot le vendría bien un poco de agua! Haz clic para registrar.',
      '🌱 ¡Broto quiere nutrirse hoy! Registra tus alimentos saludables.',
      '🏃 ¡A Zorro Veloz le vendrían bien unos pasos! ¡Salgamos a caminar!',
      '💧 ¡Hora de un sorbo! Mantén a tus mascotas felices y con energía.',
    ];

    final bodyMessage = customPetMessage ?? defaultMessages[(safeMinutes ~/ 15) % defaultMessages.length];

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _reminderId,
        channelKey: _channelKey,
        title: '🐾 Tomatelo Guardianes',
        body: bodyMessage,
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'ADD_WATER_FAST',
          label: '[ + Registro Rápido ]',
          actionType: ActionType.Default,
        ),
      ],
      schedule: NotificationInterval(
        interval: Duration(minutes: safeMinutes),
        repeats: true,
      ),
    );
  }

  Future<void> cancelHydrationReminder() async {
    await AwesomeNotifications().cancel(_reminderId);
  }

  ReminderSuggestion buildSuggestion({
    required DateTime now,
    required int fallbackMinutes,
    HydrationAdvice? hydrationAdvice,
  }) {
    final computedMinutes = switch (hydrationAdvice?.status) {
      HydrationStatus.critical => 20,
      HydrationStatus.behind => 30,
      HydrationStatus.slightlyBehind => 45,
      HydrationStatus.onTrack => hydrationAdvice?.recommendedIntervalMinutes,
      null => fallbackMinutes,
    };

    final minutesUntilNextReminder = _sanitizeMinutes(
      computedMinutes ?? fallbackMinutes,
    );
    final reason = switch (hydrationAdvice?.status) {
      HydrationStatus.critical => 'Gota-Bot está preocupado, recordatorio urgente.',
      HydrationStatus.behind =>
        'Recupera el ritmo para poner a tus mascotas en racha.',
      HydrationStatus.slightlyBehind =>
        'Recordatorio moderado para mantener constancia.',
      HydrationStatus.onTrack => 'Tus mascotas están óptimas y felices.',
      null => 'Recordatorio base de guardianes.',
    };

    return ReminderSuggestion(
      minutesUntilNextReminder: minutesUntilNextReminder,
      suggestedAt: now.add(Duration(minutes: minutesUntilNextReminder)),
      reason: reason,
    );
  }

  int _sanitizeMinutes(int minutes) {
    return minutes.clamp(_minReminderMinutes, _maxReminderMinutes).toInt();
  }
}
