import 'package:flutter/material.dart';
import 'dart:async';

class BreakStatusPopup extends StatefulWidget {
  final String breakType;
  final DateTime startTime;
  final VoidCallback onEndBreak;

  const BreakStatusPopup({
    super.key,
    required this.breakType,
    required this.startTime,
    required this.onEndBreak,
  });

  @override
  State<BreakStatusPopup> createState() => _BreakStatusPopupState();
}

class _BreakStatusPopupState extends State<BreakStatusPopup> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _duration = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Color _getBreakColor() {
    switch (widget.breakType) {
      case 'tea_break':
        return const Color(0xFFFFA726);
      case 'lunch_break':
        return const Color(0xFF66BB6A);
      case 'prayer_break':
        return const Color(0xFF42A5F5);
      case 'personal_break':
        return const Color(0xFFAB47BC);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getBreakIcon() {
    switch (widget.breakType) {
      case 'tea_break':
        return Icons.local_cafe_rounded;
      case 'lunch_break':
        return Icons.restaurant_rounded;
      case 'prayer_break':
        return Icons.mosque_rounded;
      case 'personal_break':
        return Icons.person_rounded;
      default:
        return Icons.pause_circle_rounded;
    }
  }

  String _getBreakLabel() {
    switch (widget.breakType) {
      case 'tea_break':
        return 'Tea Break';
      case 'lunch_break':
        return 'Lunch Break';
      case 'prayer_break':
        return 'Prayer Break';
      case 'personal_break':
        return 'Personal Break';
      default:
        return 'Break';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBreakColor();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getBreakIcon(),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getBreakLabel(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Started at ${_formatTime(widget.startTime)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onEndBreak,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: const Text(
                'End Break',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
