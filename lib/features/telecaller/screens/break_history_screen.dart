import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../models/leave_models.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/break_service.dart';
import '../../../widgets/error_handler.dart';

class BreakHistoryScreen extends StatefulWidget {
  const BreakHistoryScreen({super.key});

  @override
  State<BreakHistoryScreen> createState() => _BreakHistoryScreenState();
}

class _BreakHistoryScreenState extends State<BreakHistoryScreen> {
  List<BreakLog> _breakLogs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, completed, pending

  @override
  void initState() {
    super.initState();
    _loadBreakLogs();
  }

  Future<void> _loadBreakLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) return;

      final response = await BreakService.getBreakLogs(
        telecallerId: int.tryParse(currentUser.id.toString()),
      );

      if (mounted) {
        setState(() {
          // Sort by ID descending (newest first)
          _breakLogs = response..sort((a, b) => b.id.compareTo(a.id));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(context, e, onRetry: _loadBreakLogs);
      }
    }
  }

  List<BreakLog> get _filteredLogs {
    if (_selectedFilter == 'all') {
      return _breakLogs;
    }
    return _breakLogs.where((log) => log.status == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.gray;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '-';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${duration.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterChips(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : _buildBreakList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Break History',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_breakLogs.length} total breaks',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadBreakLogs,
            icon: const Icon(Icons.refresh),
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', _breakLogs.length),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Completed',
              'completed',
              _breakLogs.where((l) => l.status == 'completed').length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Pending',
              'pending',
              _breakLogs.where((l) => l.status == 'pending').length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      backgroundColor: AppTheme.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.gray,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryBlue
            : AppTheme.gray.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: AppTheme.gray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No break logs found',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.gray),
          ),
          const SizedBox(height: 8),
          Text(
            'Your break history will appear here',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.gray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakList() {
    return RefreshIndicator(
      onRefresh: _loadBreakLogs,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredLogs.length,
        itemBuilder: (context, index) {
          final log = _filteredLogs[index];
          return _buildBreakCard(log);
        },
      ),
    );
  }

  Widget _buildBreakCard(BreakLog log) {
    final statusColor = _getStatusColor(log.status);

    IconData breakIcon = Icons.coffee;
    if (log.breakType.contains('lunch')) breakIcon = Icons.restaurant;
    if (log.breakType.contains('meeting')) breakIcon = Icons.groups;
    if (log.breakType.contains('train')) breakIcon = Icons.school;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(breakIcon, size: 20, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.breakType.replaceAll('_', ' ').toUpperCase(),
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.status.toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.play_arrow,
                        'Start',
                        DateFormat('hh:mm a').format(log.startTime),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.stop,
                        'End',
                        log.endTime != null
                            ? DateFormat('hh:mm a').format(log.endTime!)
                            : 'Ongoing',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.timer,
                        'Duration',
                        _formatDuration(log.durationSeconds),
                      ),
                    ),
                  ],
                ),
                if (log.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes:',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.gray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(log.notes, style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    DateFormat('dd MMM yyyy').format(log.createdAt),
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.gray),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
