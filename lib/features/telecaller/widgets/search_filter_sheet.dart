import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SearchFilters {
  String? role;
  String? subscription;
  int profileMin;
  int profileMax;
  String? state;
  DateTime? dateFrom;
  DateTime? dateTo;
  int? month;
  int? year;
  String? callStatus;

  SearchFilters({
    this.role,
    this.subscription,
    this.profileMin = 0,
    this.profileMax = 100,
    this.state,
    this.dateFrom,
    this.dateTo,
    this.month,
    this.year,
    this.callStatus,
  });

  bool get hasActiveFilters {
    return role != null ||
        subscription != null ||
        profileMin > 0 ||
        profileMax < 100 ||
        state != null ||
        dateFrom != null ||
        dateTo != null ||
        month != null ||
        year != null ||
        callStatus != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (role != null) count++;
    if (subscription != null) count++;
    if (profileMin > 0 || profileMax < 100) count++;
    if (state != null) count++;
    if (dateFrom != null || dateTo != null) count++;
    if (month != null || year != null) count++;
    if (callStatus != null) count++;
    return count;
  }

  void clear() {
    role = null;
    subscription = null;
    profileMin = 0;
    profileMax = 100;
    state = null;
    dateFrom = null;
    dateTo = null;
    month = null;
    year = null;
    callStatus = null;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (role != null) params['filter_role'] = role!;
    if (subscription != null) params['filter_subscription'] = subscription!;
    if (profileMin > 0) params['filter_profile_min'] = profileMin.toString();
    if (profileMax < 100) params['filter_profile_max'] = profileMax.toString();
    if (state != null) params['filter_state'] = state!;
    if (dateFrom != null) {
      params['filter_date_from'] =
          '${dateFrom!.year}-${dateFrom!.month.toString().padLeft(2, '0')}-${dateFrom!.day.toString().padLeft(2, '0')}';
    }
    if (dateTo != null) {
      params['filter_date_to'] =
          '${dateTo!.year}-${dateTo!.month.toString().padLeft(2, '0')}-${dateTo!.day.toString().padLeft(2, '0')}';
    }
    if (month != null) params['filter_month'] = month.toString();
    if (year != null) params['filter_year'] = year.toString();
    if (callStatus != null) params['filter_call_status'] = callStatus!;
    return params;
  }
}

class SearchFilterSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onApply;

  const SearchFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(
      role: widget.initialFilters.role,
      subscription: widget.initialFilters.subscription,
      profileMin: widget.initialFilters.profileMin,
      profileMax: widget.initialFilters.profileMax,
      state: widget.initialFilters.state,
      dateFrom: widget.initialFilters.dateFrom,
      dateTo: widget.initialFilters.dateTo,
      month: widget.initialFilters.month,
      year: widget.initialFilters.year,
      callStatus: widget.initialFilters.callStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _filters.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoleFilter(),
                  const SizedBox(height: 20),
                  _buildSubscriptionFilter(),
                  const SizedBox(height: 20),
                  _buildProfileCompletionFilter(),
                  const SizedBox(height: 20),
                  _buildCallStatusFilter(),
                  const SizedBox(height: 20),
                  _buildStateFilter(),
                  const SizedBox(height: 20),
                  _buildDateFilter(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_filters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters${_filters.hasActiveFilters ? ' (${_filters.activeFilterCount})' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              'All',
              _filters.role == null,
              () => setState(() => _filters.role = null),
            ),
            _buildFilterChip(
              'Driver',
              _filters.role == 'driver',
              () => setState(() => _filters.role = 'driver'),
            ),
            _buildFilterChip(
              'Transporter',
              _filters.role == 'transporter',
              () => setState(() => _filters.role = 'transporter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Status',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              'All',
              _filters.subscription == null,
              () => setState(() => _filters.subscription = null),
            ),
            _buildFilterChip(
              'Active',
              _filters.subscription == 'active',
              () => setState(() => _filters.subscription = 'active'),
              color: const Color(0xFF4CAF50),
            ),
            _buildFilterChip(
              'Inactive',
              _filters.subscription == 'inactive',
              () => setState(() => _filters.subscription = 'inactive'),
              color: Colors.grey.shade600,
            ),
            _buildFilterChip(
              'Expired',
              _filters.subscription == 'expired',
              () => setState(() => _filters.subscription = 'expired'),
              color: const Color(0xFFF44336),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCompletionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Completion',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_filters.profileMin}% - ${_filters.profileMax}%',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(
            _filters.profileMin.toDouble(),
            _filters.profileMax.toDouble(),
          ),
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '${_filters.profileMin}%',
            '${_filters.profileMax}%',
          ),
          onChanged: (values) {
            setState(() {
              _filters.profileMin = values.start.round();
              _filters.profileMax = values.end.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildCallStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Call Status',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'All',
              _filters.callStatus == null,
              () => setState(() => _filters.callStatus = null),
            ),
            _buildFilterChip(
              'Pending',
              _filters.callStatus == 'pending',
              () => setState(() => _filters.callStatus = 'pending'),
            ),
            _buildFilterChip(
              'Connected',
              _filters.callStatus == 'connected',
              () => setState(() => _filters.callStatus = 'connected'),
              color: const Color(0xFF4CAF50),
            ),
            _buildFilterChip(
              'Callback',
              _filters.callStatus == 'callback',
              () => setState(() => _filters.callStatus = 'callback'),
              color: const Color(0xFFFFC107),
            ),
            _buildFilterChip(
              'Not Reachable',
              _filters.callStatus == 'not_reachable',
              () => setState(() => _filters.callStatus = 'not_reachable'),
              color: const Color(0xFFFF9800),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateFilter() {
    final states = [
      'All',
      'Delhi',
      'Maharashtra',
      'Karnataka',
      'Tamil Nadu',
      'Gujarat',
      'Rajasthan',
      'Uttar Pradesh',
      'West Bengal',
      'Punjab',
      'Haryana'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: states.map((state) {
            final isSelected = state == 'All'
                ? _filters.state == null
                : _filters.state == state;
            return _buildFilterChip(
              state,
              isSelected,
              () => setState(() => _filters.state = state == 'All' ? null : state),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration Date',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                'From',
                _filters.dateFrom,
                (date) => setState(() => _filters.dateFrom = date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                'To',
                _filters.dateTo,
                (date) => setState(() => _filters.dateTo = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(
    String label,
    DateTime? date,
    Function(DateTime?) onSelect,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        date == null
            ? label
            : '${date.day}/${date.month}/${date.year}',
        style: TextStyle(
          color: date == null ? Colors.grey.shade600 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.primaryBlue).withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.primaryBlue)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? (color ?? AppTheme.primaryBlue)
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
