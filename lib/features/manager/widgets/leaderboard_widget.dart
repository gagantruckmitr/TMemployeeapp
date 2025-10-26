import 'package:flutter/material.dart';
import '../../../models/manager_models.dart';
import '../../../core/services/manager_service.dart';
import '../../../core/theme/app_theme.dart';

class LeaderboardWidget extends StatefulWidget {
  final int managerId;

  const LeaderboardWidget({
    Key? key,
    required this.managerId,
  }) : super(key: key);

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final ManagerService _managerService = ManagerService();
  
  String _selectedPeriod = 'today';
  String _selectedMetric = 'conversions';
  bool _isLoading = true;
  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final leaderboard = await _managerService.getLeaderboard(
        period: _selectedPeriod,
        metric: _selectedMetric,
      );
      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
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
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: _leaderboard.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leaderboard.length,
                          itemBuilder: (context, index) {
                            return _buildLeaderboardCard(_leaderboard[index]);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Today', 'today'),
                _buildPeriodChip('This Week', 'week'),
                _buildPeriodChip('This Month', 'month'),
                _buildPeriodChip('All Time', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Rank By',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetricChip('Conversions', 'conversions', Icons.star),
                _buildMetricChip('Total Calls', 'calls', Icons.phone),
                _buildMetricChip('Call Duration', 'duration', Icons.timer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedPeriod = value);
            _loadLeaderboard();
          }
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    final isSelected = _selectedMetric == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedMetric = value);
            _loadLeaderboard();
          }
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry) {
    final rankColors = [
      Colors.amber[700]!,
      Colors.grey[400]!,
      Colors.brown[400]!,
    ];
    final rankColor = entry.rank <= 3 ? rankColors[entry.rank - 1] : AppTheme.primaryColor;
    final isTopThree = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree ? rankColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildRankBadge(entry.rank, rankColor, isTopThree),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    entry.mobile,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricBadge(
                        Icons.phone,
                        '${entry.totalCalls} calls',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBadge(
                        Icons.star,
                        '${entry.conversions} conv',
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBadge(
                        Icons.trending_up,
                        '${entry.conversionRate.toStringAsFixed(1)}%',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isTopThree)
              Icon(
                entry.rank == 1 ? Icons.emoji_events : Icons.military_tech,
                color: rankColor,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, Color color, bool isTopThree) {
    return Container(
      width: isTopThree ? 50 : 40,
      height: isTopThree ? 50 : 40,
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTopThree ? null : color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: isTopThree ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: isTopThree ? 18 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
