import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../../core/config/api_config.dart';
import 'break_status_popup.dart';
import 'active_break_indicator.dart';

class EnhancedLeaveBreakWidget extends StatefulWidget {
  final int telecallerId;

  const EnhancedLeaveBreakWidget({super.key, required this.telecallerId});

  @override
  State<EnhancedLeaveBreakWidget> createState() =>
      _EnhancedLeaveBreakWidgetState();
}

class _EnhancedLeaveBreakWidgetState extends State<EnhancedLeaveBreakWidget> {
  bool _isLoading = false;
  bool _isOnBreak = false;
  Map<String, dynamic>? _activeBreak;
  Map<String, dynamic>? _myStatus;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isOnBreak && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadActiveBreak(), _loadMyStatus()]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadActiveBreak() async {
    try {
      final uri =
          Uri.parse(
            '${ApiConfig.baseUrl}/simple_leave_management_api.php',
          ).replace(
            queryParameters: {
              'action': 'get_active_break',
              'telecaller_id': widget.telecallerId.toString(),
            },
          );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _isOnBreak = data['has_active_break'] ?? false;
              _activeBreak = data['data'];
            });
          }
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadMyStatus() async {
    try {
      final uri =
          Uri.parse(
            '${ApiConfig.baseUrl}/simple_leave_management_api.php',
          ).replace(
            queryParameters: {
              'action': 'get_my_status',
              'telecaller_id': widget.telecallerId.toString(),
            },
          );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _myStatus = data['data'];
            });
          }
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        if (_isOnBreak && _activeBreak != null) ...[
          ActiveBreakIndicator(
            breakType: _activeBreak!['break_type'] ?? 'personal_break',
            startTime: DateTime.parse(_activeBreak!['start_time'] ?? DateTime.now().toIso8601String()),
            onEndBreak: _endBreak,
          ),
          const SizedBox(height: 16),
        ],
        _buildBreakButtons(),
        const SizedBox(height: 16),
        _buildStatusRow(),
      ],
    );
  }

  Widget _buildBreakButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildBreakButton(
            'Tea Break',
            'tea_break',
            Icons.local_cafe_rounded,
            const Color(0xFFFFA726),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBreakButton(
            'Lunch',
            'lunch_break',
            Icons.restaurant_rounded,
            const Color(0xFF66BB6A),
            statusText: _getStatusText(),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakButton(
    String label,
    String breakType,
    IconData icon,
    Color color, {
    String? statusText,
  }) {
    final isActive = _isOnBreak && _activeBreak?['break_type'] == breakType;

    return GestureDetector(
      onTap: isActive ? _endBreak : () => _startBreak(breakType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (statusText != null)
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildSecondaryBreakButton(
            'Prayer',
            'prayer_break',
            Icons.mosque_rounded,
            const Color(0xFF42A5F5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildSecondaryBreakButton(
            'Personal',
            'personal_break',
            Icons.person_rounded,
            const Color(0xFFAB47BC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: _buildOnlineStatus()),
      ],
    );
  }

  Widget _buildSecondaryBreakButton(
    String label,
    String breakType,
    IconData icon,
    Color color,
  ) {
    final isActive = _isOnBreak && _activeBreak?['break_type'] == breakType;

    return GestureDetector(
      onTap: isActive ? _endBreak : () => _startBreak(breakType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatus() {
    final status = _myStatus?['current_status'] ?? 'offline';
    final isOnline = status == 'online';
    final onlineDuration =
        _myStatus?['online_duration_formatted'] ?? '00:00:00';
    final todayConnected = _myStatus?['today_connected'] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOnline
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: isOnline ? const Color(0xFF10B981) : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                onlineDuration,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_in_talk_rounded,
              size: 12,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '$todayConnected Calls',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText() {
    final status = _myStatus?['current_status'] ?? 'offline';
    return status.toUpperCase();
  }

  Future<void> _startBreak(String breakType) async {
    if (!mounted) return;
    
    try {
      debugPrint('Starting break: $breakType for telecaller ${widget.telecallerId}');
      
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/enhanced_leave_management_api.php?action=start_break',
      );
      
      final requestBody = json.encode({
        'telecaller_id': widget.telecallerId,
        'break_type': breakType,
      });
      
      debugPrint('Request URL: $uri');
      debugPrint('Request Body: $requestBody');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            await _loadData();
            // Show break popup
            _showBreakPopup(breakType);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? 'Failed to start break'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting break: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBreakPopup(String breakType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BreakStatusPopup(
          breakType: breakType,
          startTime: DateTime.now(),
          onEndBreak: () {
            Navigator.of(context).pop();
            _endBreak();
          },
        ),
      ),
    );
  }

  Future<void> _endBreak() async {
    if (!mounted) return;
    
    try {
      debugPrint('Ending break for telecaller ${widget.telecallerId}');
      
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/enhanced_leave_management_api.php?action=end_break',
      );
      
      final requestBody = json.encode({'telecaller_id': widget.telecallerId});
      
      debugPrint('Request URL: $uri');
      debugPrint('Request Body: $requestBody');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Break ended'),
                backgroundColor: Colors.green,
              ),
            );
            await _loadData();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['error'] ?? 'Failed to end break'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error ending break: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
