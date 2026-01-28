import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class MargdarshakNotificationService {
  static final MargdarshakNotificationService _instance =
      MargdarshakNotificationService._internal();
  static MargdarshakNotificationService get instance => _instance;

  MargdarshakNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) print('User granted provisional permission');
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
      return;
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );

    // 3. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      }

      _showLocalNotification(message);
    });

    // 5. Handle Message Open App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('A new onMessageOpenedApp event was published!');
      _handleMessageOpen(message);
    });

    _isInitialized = true;
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) print("FCM Token: $token");
      return token;
    } catch (e) {
      if (kDebugMode) print("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'margdarshak_channel', // id
            'Margdarshak Notifications', // title
            channelDescription: 'Important updates for Margdarshaks',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload);
      _navigateBasedOnData(data);
    } catch (e) {
      if (kDebugMode) print('Error parsing payload: $e');
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    _navigateBasedOnData(message.data);
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    // Implement navigation logic based on notification data
    // For example:
    // if (data['type'] == 'driver_update') {
    //   // Navigate to drivers page
    // }
    if (kDebugMode) print("Navigate to: $data");
  }
}
