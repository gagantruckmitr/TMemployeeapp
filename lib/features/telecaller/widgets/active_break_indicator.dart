import 'package:flutter/material.dart';
import 'dart:async';

class ActiveBreakIndicator extends StatefulWidget {
  final String breakType;
  final DateTime startTime;
  final VoidCallback onEndBreak;

  const ActiveBreakIndicator({
    super.key,
    required this.breakType,
    required this.startTime,
    required this.onEndBreak,
  });

  @override
  State<ActiveBreakIndicator> createState() => _ActiveBreakIndicatorState();
}

class _ActiveBreakIndicatorState extends State<ActiveBreakIndicator> {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getBreakIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBreakLabel(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onEndBreak,
            icon: const Icon(Icons.stop_rounded, size: 18),
            label: const Text(
              'End',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
