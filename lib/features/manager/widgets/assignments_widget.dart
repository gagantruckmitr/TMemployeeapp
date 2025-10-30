import 'package:flutter/material.dart';
import '../../../core/services/manager_service.dart';

class AssignmentsWidget extends StatefulWidget {
  final int managerId;

  const AssignmentsWidget({
    super.key,
    required this.managerId,
  });

  @override
  State<AssignmentsWidget> createState() => _AssignmentsWidgetState();
}

class _AssignmentsWidgetState extends State<AssignmentsWidget> {
  final ManagerService _managerService = ManagerService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _assignments = [];
  List<dynamic> _filteredAssignments = [];
  bool _isLoading = true;
  int? _selectedTelecaller;

  // Modern teal green color scheme
  static const Color _tealPrimary = Color(0xFF14B8A6);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _searchController.addListener(_filterAssignments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAssignments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAssignments = _assignments;
      } else {
        _filteredAssignments = _assignments.where((assignment) {
          final telecallerName = (assignment['telecaller_name'] ?? '').toString().toLowerCase();
          final driverName = (assignment['driver_name'] ?? '').toString().toLowerCase();
          final driverMobile = (assignment['driver_mobile'] ?? '').toString().toLowerCase();
          final driverState = (assignment['driver_state'] ?? '').toString().toLowerCase();
          final driverCity = (assignment['driver_city'] ?? '').toString().toLowerCase();
          
          return telecallerName.contains(query) ||
                 driverName.contains(query) ||
                 driverMobile.contains(query) ||
                 driverState.contains(query) ||
                 driverCity.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);

    try {
      final data = await _managerService.getDriverAssignments(
        telecallerId: _selectedTelecaller,
      );
      if (mounted) {
        setState(() {
          _assignments = data['assignments'] as List;
          _filteredAssignments = _assignments;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _tealPrimary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(),
              Divider(height: 1, color: _borderColor),
              _buildSearchBar(),
              Divider(height: 1, color: _borderColor),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredAssignments.isEmpty
                        ? _buildEmptyState()
                        : _buildAssignmentsList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_rounded, color: _tealPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lead Assignments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _loadAssignments,
              icon: const Icon(Icons.refresh_rounded, color: _tealPrimary, size: 20),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, mobile, or location...',
          hintStyle: const TextStyle(
            color: _textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _tealPrimary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _textSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _tealPrimary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAssignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = _filteredAssignments[index];
        return _buildSimpleAssignmentCard(assignment);
      },
    );
  }

  Widget _buildSimpleAssignmentCard(Map<String, dynamic> assignment) {
    final telecallerName = assignment['telecaller_name'] ?? 'Unknown';
    final driverName = assignment['driver_name'] ?? 'Unknown Driver';
    final driverMobile = assignment['driver_mobile'] ?? '';
    final driverState = assignment['driver_state'] ?? '';
    final driverCity = assignment['driver_city'] ?? '';
    final priority = assignment['priority'] ?? 'medium';

    Color priorityColor;
    String priorityLabel;

    switch (priority) {
      case 'urgent':
        priorityColor = const Color(0xFFEF4444);
        priorityLabel = 'URGENT';
        break;
      case 'high':
        priorityColor = const Color(0xFFF59E0B);
        priorityLabel = 'HIGH';
        break;
      case 'medium':
        priorityColor = _tealPrimary;
        priorityLabel = 'MEDIUM';
        break;
      default:
        priorityColor = const Color(0xFF6B7280);
        priorityLabel = 'LOW';
    }

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with priority badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.assignment_rounded, color: _tealPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Assignment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Telecaller info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _tealPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.headset_mic_rounded,
                        color: _tealPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Telecaller',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            telecallerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  height: 1,
                  color: _borderColor,
                ),
                const SizedBox(height: 12),
                // Driver info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: priorityColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Driver',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Contact details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android_rounded,
                            size: 16,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            driverMobile,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (driverCity.isNotEmpty || driverState.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$driverCity${driverCity.isNotEmpty && driverState.isNotEmpty ? ', ' : ''}$driverState',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading assignments...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _tealPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.assignment_outlined,
              size: 64,
              color: _tealPrimary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'No results found' : 'No assignments yet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Lead assignments will appear here',
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
