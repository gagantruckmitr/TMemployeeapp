import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/telecaller_status_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/theme/app_theme.dart';

class StatusControlWidget extends StatefulWidget {
  const StatusControlWidget({super.key});

  @override
  State<StatusControlWidget> createState() => _StatusControlWidgetState();
}

class _StatusControlWidgetState extends State<StatusControlWidget> {
  String _currentStatus = 'online';
  bool _isOnBreak = false;
  DateTime? _breakStartTime;
  Timer? _breakTimer;
  Duration _breakDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    final user = RealAuthService.instance.currentUser;
    if (user?.id != null) {
      final status = await TelecallerStatusService.instance.getStatus(user!.id);
      if (status != null && mounted) {
        setState(() {
          _currentStatus = status['current_status'] ?? 'online';
          _isOnBreak = _currentStatus == 'break';
          if (_isOnBreak && status['break_start_time'] != null) {
            _breakStartTime = DateTime.parse(status['break_start_time']);
            _startBreakTimer();
          }
        });
      }
    }
  }

  void _startBreakTimer() {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_breakStartTime != null && mounted) {
        setState(() {
          _breakDuration = DateTime.now().difference(_breakStartTime!);
        });
      }
    });
  }

  void _stopBreakTimer() {
    _breakTimer?.cancel();
    _breakTimer = null;
    _breakDuration = Duration.zero;
  }

  Future<void> _startBreak() async {
    final user = RealAuthService.instance.currentUser;
    if (user?.id == null) return;

    final success = await TelecallerStatusService.instance.startBreak(user!.id);
    if (success && mounted) {
      setState(() {
        _isOnBreak = true;
        _currentStatus = 'break';
        _breakStartTime = DateTime.now();
      });
      _startBreakTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Break started'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _endBreak() async {
    final user = RealAuthService.instance.currentUser;
    if (user?.id == null) return;

    final success = await TelecallerStatusService.instance.endBreak(user!.id);
    if (success && mounted) {
      _stopBreakTimer();
      setState(() {
        _isOnBreak = false;
        _currentStatus = 'online';
        _breakStartTime = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Break ended - Back to work!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    final user = RealAuthService.instance.currentUser;
    if (user?.id == null) return;

    final success = await TelecallerStatusService.instance.updateStatus(user!.id, newStatus);
    if (success && mounted) {
      setState(() {
        _currentStatus = newStatus;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status changed to ${newStatus.toUpperCase()}'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopBreakTimer();
    super.dispose();
  }

  String _formatBreakDuration() {
    final hours = _breakDuration.inHours;
    final minutes = _breakDuration.inMinutes % 60;
    final seconds = _breakDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'online':
        return Colors.green;
      case 'break':
        return Colors.orange;
      case 'busy':
        return Colors.red;
      case 'on_call':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStatusColor().withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Status',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Break Timer (if on break)
          if (_isOnBreak)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.coffee, color: Colors.orange.shade700, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Break Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatBreakDuration(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _endBreak,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('End Break & Resume Work'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Status Controls (if not on break)
          if (!_isOnBreak)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Break Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startBreak,
                      icon: const Icon(Icons.coffee),
                      label: const Text('Take a Break'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Status buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _changeStatus('online'),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Available'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: BorderSide(color: Colors.green.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _changeStatus('busy'),
                          icon: const Icon(Icons.do_not_disturb, size: 18),
                          label: const Text('Busy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Info text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your manager can see your live status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
