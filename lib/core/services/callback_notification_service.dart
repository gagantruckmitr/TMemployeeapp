import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CallbackNotification {
  final String id;
  final String contactName;
  final String contactPhone;
  final String contactTmid;
  final DateTime scheduledTime;
  final String remarks;
  final bool isDismissed;

  CallbackNotification({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    required this.contactTmid,
    required this.scheduledTime,
    required this.remarks,
    this.isDismissed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'contactTmid': contactTmid,
        'scheduledTime': scheduledTime.toIso8601String(),
        'remarks': remarks,
        'isDismissed': isDismissed,
      };

  factory CallbackNotification.fromJson(Map<String, dynamic> json) {
    return CallbackNotification(
      id: json['id'] as String,
      contactName: json['contactName'] as String,
      contactPhone: json['contactPhone'] as String,
      contactTmid: json['contactTmid'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      remarks: json['remarks'] as String,
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}

class CallbackNotificationService extends ChangeNotifier {
  static final CallbackNotificationService _instance =
      CallbackNotificationService._internal();
  factory CallbackNotificationService() => _instance;
  CallbackNotificationService._internal();

  List<CallbackNotification> _notifications = [];
  static const String _storageKey = 'callback_notifications';

  List<CallbackNotification> get activeNotifications =>
      _notifications.where((n) => !n.isDismissed).toList();

  Future<void> initialize() async {
    debugPrint('🚀 Initializing CallbackNotificationService');
    await _loadNotifications();
    debugPrint('📱 Loaded ${_notifications.length} notifications');
    for (var n in _notifications) {
      debugPrint('   - ${n.contactName}: ${n.scheduledTime} (dismissed: ${n.isDismissed})');
    }
    _cleanupOldNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        _notifications = jsonList
            .map((json) => CallbackNotification.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data =
          json.encode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification(CallbackNotification notification) async {
    debugPrint('💾 Adding notification: ${notification.contactName}');
    debugPrint('   Scheduled for: ${notification.scheduledTime}');
    debugPrint('   TMID: ${notification.contactTmid}');
    _notifications.add(notification);
    await _saveNotifications();
    debugPrint('✅ Notification saved. Total: ${_notifications.length}');
    notifyListeners();
  }

  Future<void> dismissNotification(String id) async {
    debugPrint('🔕 Dismissing notification: $id');
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = CallbackNotification(
        id: _notifications[index].id,
        contactName: _notifications[index].contactName,
        contactPhone: _notifications[index].contactPhone,
        contactTmid: _notifications[index].contactTmid,
        scheduledTime: _notifications[index].scheduledTime,
        remarks: _notifications[index].remarks,
        isDismissed: true,
      );
      await _saveNotifications();
      debugPrint('✅ Notification dismissed and saved');
      notifyListeners();
      debugPrint('📢 Listeners notified');
    } else {
      debugPrint('❌ Notification not found: $id');
    }
  }

  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  void _cleanupOldNotifications() {
    final now = DateTime.now();
    _notifications.removeWhere((n) =>
        n.isDismissed &&
        now.difference(n.scheduledTime).inHours > 24);
    _saveNotifications();
  }

  CallbackNotification? getUpcomingNotification() {
    final now = DateTime.now();
    final upcoming = activeNotifications
        .where((n) => n.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  List<CallbackNotification> getOverdueNotifications() {
    final now = DateTime.now();
    return activeNotifications
        .where((n) => n.scheduledTime.isBefore(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<void> markCallbackCompleted(String contactTmid) async {
    debugPrint('🔍 Marking callback completed for TMID: $contactTmid');
    
    // Find and dismiss all notifications for this contact
    final notificationsToRemove = _notifications
        .where((n) => n.contactTmid == contactTmid && !n.isDismissed)
        .toList();

    debugPrint('📋 Found ${notificationsToRemove.length} notifications to dismiss');
    
    for (final notification in notificationsToRemove) {
      debugPrint('   Dismissing: ${notification.contactName} (${notification.id})');
      await dismissNotification(notification.id);
    }
    
    debugPrint('✅ All callbacks dismissed for TMID: $contactTmid');
  }

  bool hasActiveCallbackFor(String contactTmid) {
    return activeNotifications.any((n) => n.contactTmid == contactTmid);
  }
}
