import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../core/services/callback_notification_service.dart';
import '../features/telecaller/screens/call_history_screen.dart';

// Global navigator key for navigation from overlay
final GlobalKey<NavigatorState> callbackNavigatorKey = GlobalKey<NavigatorState>();

class CallbackNotificationOverlay extends StatefulWidget {
  final Widget child;

  const CallbackNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<CallbackNotificationOverlay> createState() =>
      _CallbackNotificationOverlayState();
}

class _CallbackNotificationOverlayState
    extends State<CallbackNotificationOverlay>
    with TickerProviderStateMixin {
  final CallbackNotificationService _notificationService =
      CallbackNotificationService();
  
  Offset _position = const Offset(20, 100);
  Timer? _countdownTimer;
  Timer? _tickSoundTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  CallbackNotification? _activeNotification;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationUpdate);
    // Check immediately on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpcomingCallback();
    });
    _startMonitoring();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tickSoundTimer?.cancel();
    _audioPlayer.dispose();
    _notificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    if (mounted) {
      debugPrint('🔔 Notification service updated - rechecking callbacks');
      _checkForUpcomingCallback();
    }
  }

  void _startMonitoring() {
    debugPrint('🔄 Starting callback monitoring (every 10 seconds)');
    // Check every 10 seconds for upcoming callbacks
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        debugPrint('⏱️ Timer tick - checking callbacks...');
        _checkForUpcomingCallback();
      } else {
        debugPrint('🛑 Widget unmounted, stopping timer');
        timer.cancel();
      }
    });
  }

  void _checkForUpcomingCallback() {
    if (!mounted) return;
    
    final now = DateTime.now();
    final notifications = _notificationService.activeNotifications;

    debugPrint('🔍 Checking callbacks at ${now.toString()}');
    debugPrint('📋 Total active notifications: ${notifications.length}');

    for (var n in notifications) {
      final diff = n.scheduledTime.difference(now);
      debugPrint(
          '  - ${n.contactName}: scheduled at ${n.scheduledTime}, diff: ${diff.inMinutes}m ${diff.inSeconds % 60}s');
    }

    // Find callbacks within 5 minutes (up to 5:59)
    final upcomingCallback = notifications.where((n) {
      final difference = n.scheduledTime.difference(now);
      final isUpcoming = difference.inSeconds > 0 && difference.inSeconds <= 300; // 300 seconds = 5 minutes
      if (isUpcoming) {
        debugPrint('✅ Found upcoming callback: ${n.contactName}');
      }
      return isUpcoming;
    }).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (upcomingCallback.isNotEmpty) {
      final notification = upcomingCallback.first;
      debugPrint('🎯 Showing notification for: ${notification.contactName}');
      if (_activeNotification?.id != notification.id) {
        setState(() {
          _activeNotification = notification;
          _remainingSeconds =
              notification.scheduledTime.difference(now).inSeconds;
        });
        debugPrint('⏰ Countdown started: $_remainingSeconds seconds');
        _startCountdown();
        _startTickSound();
      }
    } else {
      debugPrint('❌ No upcoming callbacks within 5 minutes');
      if (_activeNotification != null) {
        debugPrint('🔕 Hiding active notification');
        setState(() {
          _activeNotification = null;
        });
        _stopCountdown();
        _stopTickSound();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        // When timer reaches 00:00, auto-navigate to callback screen
        if (_remainingSeconds == 0 && mounted) {
          debugPrint('⏰ Timer reached 00:00 - Auto-navigating to callbacks');
          _navigateToCallbacks(context);
        }
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
  }

  void _startTickSound() {
    _tickSoundTimer?.cancel();
    // Play tick sound every 2 seconds
    _tickSoundTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted && _activeNotification != null) {
        try {
          await _audioPlayer.play(AssetSource('sounds/tick.mp3'), volume: 0.3);
        } catch (e) {
          // Fallback: use system sound if asset not found
          debugPrint('Tick sound not found: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTickSound() {
    _tickSoundTimer?.cancel();
    _audioPlayer.stop();
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _navigateToCallbacks(BuildContext context) {
    _stopTickSound();
    debugPrint('🧭 Navigating to callback section...');
    
    try {
      // Use global navigator key to navigate
      final navigator = callbackNavigatorKey.currentState;
      if (navigator != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const CallHistoryScreen(
              initialFilter: 'callback_later',
            ),
          ),
        );
        debugPrint('✅ Navigation successful');
      } else {
        debugPrint('❌ Navigator key not found');
        // Fallback: try context navigator
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => const CallHistoryScreen(
              initialFilter: 'callback_later',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_activeNotification != null)
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: _buildFloatingWidget(context),
          ),
      ],
    );
  }

  Widget _buildFloatingWidget(BuildContext context) {
    if (_activeNotification == null) return const SizedBox.shrink();

    // Change color to red when 20 seconds or less remaining
    final isUrgent = _remainingSeconds <= 20;
    final gradientColors = isUrgent
        ? [Colors.red.shade400, Colors.red.shade700]
        : [Colors.blue.shade400, Colors.blue.shade700];
    final shadowColor = isUrgent ? Colors.red : Colors.blue;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _position = Offset(
            (_position.dx + details.delta.dx).clamp(
              0.0,
              MediaQuery.of(context).size.width - 80,
            ),
            (_position.dy + details.delta.dy).clamp(
              0.0,
              MediaQuery.of(context).size.height - 80,
            ),
          );
        });
      },
      onTap: () => _navigateToCallbacks(context),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pulsing ring animation
              Positioned.fill(
                child: _PulsingRing(),
              ),
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.alarm,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCountdown(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _activeNotification!.contactName.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // No close button - uncloseable until callback time
            ],
          ),
        ),
      ),
    );
  }
}

// Pulsing ring animation widget
class _PulsingRing extends StatefulWidget {
  const _PulsingRing();

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 1.0 - _animation.value),
              width: 3,
            ),
          ),
        );
      },
    );
  }
}
