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

  static const String _channelKey = 'hydration_reminders';
  static const int _reminderId = 1001;
  static const int _minReminderMinutes = 15;
  static const int _maxReminderMinutes = 120;

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: _channelKey,
        channelName: 'Recordatorios de hidratación',
        channelDescription: 'Notificaciones para tomar agua',
        defaultColor: const Color(0xFF4FA3FF),
        importance: NotificationImportance.High,
        playSound: true,
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

  Future<void> scheduleHydrationReminder({required int minutes}) async {
    await cancelHydrationReminder();

    final safeMinutes = _sanitizeMinutes(minutes);
    final messages = <String>[
      'Tu botella te extraña 💧 ¡Hora de un sorbito feliz!',
      'Mini pausa acuática 🚰 Tu yo del futuro te lo agradecerá.',
      '¡Ping de hidratación! 😄 Un vaso y seguimos brillando.',
      'Agüita time 🥤 Un brindis por esa energía bonita.',
      'Recordatorio amistoso: tu cuerpo pide agua con cariño 💙',
    ];

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _reminderId,
        channelKey: _channelKey,
        title: 'Tomatelo te cuida',
        body: messages[(safeMinutes ~/ 15) % messages.length],
        notificationLayout: NotificationLayout.Default,
      ),
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
      HydrationStatus.critical => 'Recordatorio intensivo por atraso alto.',
      HydrationStatus.behind =>
        'Recordatorio frecuente para recuperar el ritmo.',
      HydrationStatus.slightlyBehind =>
        'Recordatorio moderado para mantener constancia.',
      HydrationStatus.onTrack => 'Vas bien, mantenemos un ritmo saludable.',
      null => 'Recordatorio base de hidratación.',
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
