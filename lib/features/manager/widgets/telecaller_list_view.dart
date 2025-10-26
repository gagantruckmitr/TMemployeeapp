import 'package:flutter/material.dart';
import '../../../models/manager_models.dart';
import '../../../core/theme/app_theme.dart';
import '../telecaller_detail_page_modern.dart';

class TelecallerListView extends StatefulWidget {
  final List<TelecallerInfo> telecallers;
  final int managerId;
  final VoidCallback onRefresh;

  const TelecallerListView({
    Key? key,
    required this.telecallers,
    required this.managerId,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<TelecallerListView> createState() => _TelecallerListViewState();
}

class _TelecallerListViewState extends State<TelecallerListView> {
  String _searchQuery = '';
  TelecallerStatus? _filterStatus;

  List<TelecallerInfo> get _filteredTelecallers {
    return widget.telecallers.where((telecaller) {
      final matchesSearch = telecaller.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          telecaller.mobile.contains(_searchQuery);
      final matchesStatus = _filterStatus == null || telecaller.currentStatus == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: _filteredTelecallers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTelecallers.length,
                    itemBuilder: (context, index) {
                      return _buildTelecallerCard(_filteredTelecallers[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search telecallers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('Online', TelecallerStatus.online),
                _buildFilterChip('On Call', TelecallerStatus.onCall),
                _buildFilterChip('Offline', TelecallerStatus.offline),
                _buildFilterChip('Break', TelecallerStatus.break_),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TelecallerStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = selected ? status : null);
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTelecallerCard(TelecallerInfo telecaller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelecallerDetailPageModern(
                telecallerId: telecaller.id,
                managerId: widget.managerId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildAvatar(telecaller),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          telecaller.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          telecaller.mobile,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(telecaller.currentStatus),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStat('Calls', telecaller.totalCallsToday.toString(), Icons.phone),
                  _buildStat('Connected', telecaller.connectedToday.toString(), Icons.check_circle),
                  _buildStat('Interested', telecaller.interestedToday.toString(), Icons.star),
                  _buildStat('Rate', '${telecaller.conversionRate.toStringAsFixed(1)}%', Icons.trending_up),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(TelecallerInfo telecaller) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          telecaller.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TelecallerStatus status) {
    Color color;
    switch (status) {
      case TelecallerStatus.online:
        color = Colors.green;
        break;
      case TelecallerStatus.onCall:
        color = Colors.blue;
        break;
      case TelecallerStatus.break_:
        color = Colors.orange;
        break;
      case TelecallerStatus.busy:
        color = Colors.amber;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No telecallers found',
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
