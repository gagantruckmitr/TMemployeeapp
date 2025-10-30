import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/driver_contact_card.dart';

class PendingCallsScreen extends StatefulWidget {
  const PendingCallsScreen({super.key});

  @override
  State<PendingCallsScreen> createState() => _PendingCallsScreenState();
}

class _PendingCallsScreenState extends State<PendingCallsScreen>
    with AutomaticKeepAliveClientMixin {
  List<DriverContact>? _pendingLeads;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPendingLeads();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingLeads() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final leads = await SmartCallingService.instance.getDrivers(forceRefresh: true);

      if (mounted) {
        setState(() {
          _pendingLeads = leads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingLeads = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pending calls: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadPendingLeads();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Calls',
                              style: AppTheme.headingMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Leads not yet called',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pendingLeads != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_pendingLeads!.length}',
                            style: AppTheme.titleMedium.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingLeads == null || _pendingLeads!.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _pendingLeads!.length,
                            itemBuilder: (context, index) {
                              final lead = _pendingLeads![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DriverContactCard(
                                  contact: lead,
                                  onCallPressed: () => _initiateCall(lead),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Pending Calls',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All assigned leads have been called',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _initiateCall(DriverContact lead) {
    HapticFeedback.lightImpact();
    // Navigate to smart calling with this lead
    // You can implement this based on your navigation setup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${lead.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
