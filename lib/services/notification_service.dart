import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelKey = 'hydration_reminders';
  static const int _reminderId = 1001;

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

    final safeMinutes = minutes < 15 ? 15 : minutes;
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
        preciseAlarm: true,
      ),
    );
  }

  Future<void> cancelHydrationReminder() async {
    await AwesomeNotifications().cancel(_reminderId);
  }
}
