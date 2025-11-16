import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/call_hit_service.dart';

class CallHitKPICard extends StatefulWidget {
  const CallHitKPICard({super.key});

  @override
  State<CallHitKPICard> createState() => _CallHitKPICardState();
}

class _CallHitKPICardState extends State<CallHitKPICard> {
  bool _isLoading = true;
  int _todayCalls = 0;
  int _weekCalls = 0;
  int _monthCalls = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final todayStats = await CallHitService.instance.getCallHitStats(period: 'today');
      final weekStats = await CallHitService.instance.getCallHitStats(period: 'week');
      final monthStats = await CallHitService.instance.getCallHitStats(period: 'month');
      
      if (mounted) {
        setState(() {
          _todayCalls = todayStats['data']?['total_calls'] ?? 0;
          _weekCalls = weekStats['data']?['total_calls'] ?? 0;
          _monthCalls = monthStats['data']?['total_calls'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Call Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isLoading) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Today',
                      _todayCalls.toString(),
                      Icons.today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Week',
                      _weekCalls.toString(),
                      Icons.date_range,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Month',
                      _monthCalls.toString(),
                      Icons.calendar_month,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
