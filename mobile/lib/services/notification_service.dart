import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/api_service.dart';

/// Top-level background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // show a simple local notification when background message arrives
  final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await fln.initialize(initSettings);

  final notification = message.notification;
  if (notification != null) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ews_alerts_channel',
          'EWS Alerts',
          channelDescription: 'Channel for EWS push alerts',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await fln.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data.toString(),
    );
  }
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocal =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _onMessageController =
      StreamController.broadcast();

  Stream<RemoteMessage> get onMessageStream => _onMessageController.stream;

  bool _initialized = false;

  Future<void> init({String? targetArea}) async {
    if (_initialized) return;

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocal.initialize(initializationSettings);

    // Request permission (iOS) and get token
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      final token = await _messaging.getToken();
      if (kDebugMode) debugPrint('[NotificationService] FCM token: $token');

      if (token != null) {
        // send token to backend so it can push
        try {
          await ApiService().subscribePushToken(
            token: token,
            targetArea: targetArea,
          );
        } catch (e) {
          if (kDebugMode)
            debugPrint(
              '[NotificationService] Failed to register token with backend: $e',
            );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] getToken error: $e');
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // show local notification
      final notification = message.notification;
      if (notification != null) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'ews_alerts_channel',
              'EWS Alerts',
              channelDescription: 'Channel for EWS push alerts',
              importance: Importance.high,
              priority: Priority.high,
            );
        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
        );
        await _flutterLocal.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformDetails,
          payload: message.data.toString(),
        );
      }

      // Emit event for UI to react (refresh lists etc.)
      _onMessageController.add(message);
    });

    _initialized = true;
  }

  void dispose() {
    _onMessageController.close();
  }
}
