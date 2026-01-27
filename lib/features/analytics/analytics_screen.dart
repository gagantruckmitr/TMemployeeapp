import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/analytics_service.dart';
import '../../models/analytics_kpi_model.dart';
import '../calls/call_history_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Today';
  bool _isLoading = true;
  AnalyticsKPIResponse? _data;
  String? _errorMessage;

  final Map<String, String> _periodMap = {
    'Today': 'today',
    'Yesterday': 'yesterday',
    'This Week': 'this_week',
    'This Month': 'this_month',
    'All': 'all',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filter = _periodMap[_selectedPeriod] ?? 'today';
      final data = await AnalyticsService.fetchAnalytics(filter: filter);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periodMap.keys.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPeriod = period);
                          _loadData();
                        }
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  void _navigateToHistory(String title) {
    String? feedbackFilter;

    // Map KPI title to CallHistoryScreen feedback filter
    switch (title) {
      case 'Connected':
        feedbackFilter = 'Connected';
        break;
      case 'Not Connected':
        feedbackFilter = 'Not Connected';
        break;
      case 'Callbacks':
        feedbackFilter = 'Callback Later';
        break;
      // 'Match Making' and 'Interviews Done' are typically subsets of Connected
      // or specific statuses, but standard filters are limited.
      // Mapping them to 'Connected' or leaving null for now.
      case 'Match Making':
        feedbackFilter = 'Connected';
        break;
      case 'Interviews Done':
        feedbackFilter = 'Connected';
        break;
      default:
        feedbackFilter = null;
    }

    // Map display period to API period for history
    // Analytics uses: 'Today', 'Yesterday', 'This Week', 'This Month', 'All'
    // History uses: 'all', 'today', 'week', 'month'
    String historyPeriod = 'all';
    switch (_selectedPeriod) {
      case 'Today':
        historyPeriod = 'today';
        break;
      case 'This Week':
        historyPeriod = 'week';
        break;
      case 'This Month':
        historyPeriod = 'month';
        break;
      case 'All':
        historyPeriod = 'all';
        break;
      case 'Yesterday':
        // History screen might not support 'yesterday' explicitly in tabs,
        // so falling back to 'all' or 'week' might be safer, or assuming it handles it.
        // Looking at CallHistoryScreen, tabs are: All, Today, Week, Month.
        // 'Yesterday' is not supported directly in tabs.
        // Best fallback is 'week' or 'all' to ensure data visibility.
        historyPeriod = 'week';
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallHistoryScreen(
          initialPeriod: historyPeriod,
          initialFeedbackFilter: feedbackFilter,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null) return const SizedBox();

    final calls = _data!.calls;
    final matches = _data!.matches;

    // Define KPI items
    final kpis = [
      _KPIItem(
        title: 'Total Calls',
        value: calls.totalCalls.toString(),
        color: Colors.blue,
        icon: Icons.phone,
      ),
      _KPIItem(
        title: 'Connected',
        value: calls.connectedCalls.toString(),
        color: Colors.green,
        icon: Icons.phone_in_talk,
      ),
      _KPIItem(
        title: 'Not Connected',
        value: calls.notConnectedCalls.toString(),
        color: Colors.red,
        icon: Icons.phone_missed,
      ),
      _KPIItem(
        title: 'Callbacks',
        value: calls.callbackCalls.toString(),
        color: Colors.orange,
        icon: Icons.call_missed_outgoing,
      ),
      _KPIItem(
        title: 'Match Making',
        value: matches.totalMatchStatus.toString(),
        color: Colors.purple,
        icon: Icons.people_outline,
      ),
      _KPIItem(
        title: 'Interviews Done',
        value: _data!.totalInterviewDone.toString(),
        color: Colors.teal,
        icon: Icons.check_circle_outline,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: kpis.length,
            itemBuilder: (context, index) {
              return _buildKPICard(kpis[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(_KPIItem item) {
    return GestureDetector(
      onTap: () => _navigateToHistory(item.title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _KPIItem {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  _KPIItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
}
