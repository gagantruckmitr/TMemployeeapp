import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/toll_free_service.dart';
import '../../../core/services/toll_free_feedback_service.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/easygo_ivr_service.dart';
import '../../../models/toll_free_lead_model.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/utils/state_code_mapper.dart';
import '../../../widgets/profile_completion_avatar.dart';
import '../widgets/call_feedback_modal.dart';
import 'toll_free_history_screen.dart';
import 'toll_free_profile_details_screen.dart';

class TollFreeSearchScreen extends StatefulWidget {
  const TollFreeSearchScreen({super.key});

  @override
  State<TollFreeSearchScreen> createState() => _TollFreeSearchScreenState();
}

class _TollFreeSearchScreenState extends State<TollFreeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TollFreeService _service = TollFreeService.instance;

  TollFreeUser? _searchResult;
  bool _isSearching = false;
  String? _error;
  
  // Call history
  List<Map<String, dynamic>> _callHistory = [];
  bool _isLoadingHistory = false;
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final history = await TollFreeFeedbackService.instance.fetchCallHistory();
      if (mounted) {
        setState(() {
          _callHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error = 'Please enter TMID or mobile number';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _searchResult = null;
    });

    try {
      final result = await _service.searchUser(query);

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _searchResult = TollFreeUser.fromJson(result);
          _isSearching = false;
        });
      } else {
        setState(() {
          _error = 'No user found with this TMID or mobile number';
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _makeCall(TollFreeUser user) async {
    try {
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📞 Initiating IVR call to ${user.name}...'),
          backgroundColor: AppTheme.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Use IVR calling instead of direct calling
      final result = await EasyGoIVRService.initiateCall(
        exten: currentUser.mobile,
        number: user.mobile,
        callerId: currentUser.id,
        contactId: user.uniqueId,
        contactType: user.role,
        driverName: user.name,
        callSource: 'toll-free',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ IVR call initiated to ${user.name}'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          _showFeedbackModal(user);
        }
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Call failed: ${result['error'] ?? "Unknown error"}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $error'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFeedbackModal(TollFreeUser user) {
    final contact = DriverContact(
      id: user.id.toString(),
      tmid: user.uniqueId,
      name: user.name,
      company: user.role,
      phoneNumber: user.mobile,
      state: '',
      subscriptionStatus: user.hasSubscription
          ? SubscriptionStatus.active
          : SubscriptionStatus.inactive,
      status: CallStatus.pending,
      lastFeedback: null,
      lastCallTime: DateTime.now(),
      remarks: null,
      paymentInfo: PaymentInfo.none(),
      registrationDate: DateTime.now(),
      profileCompletion: null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallFeedbackModal(
        contact: contact,
        allowDismiss: true,
        onFeedbackSubmitted: (feedback) {
          Navigator.of(context).pop();
          _handleFeedbackSubmitted(user, feedback);
        },
      ),
    );
  }

  Future<void> _handleFeedbackSubmitted(
    TollFreeUser user,
    CallFeedback feedback,
  ) async {
    if (!mounted) return;

    final result = await TollFreeFeedbackService.instance.submitFeedback(
      user: user,
      feedback: feedback,
    );

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Feedback saved for ${user.name}'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear search and refresh history after feedback
      setState(() {
        _searchResult = null;
        _searchController.clear();
      });
      
      // Refresh call history
      _loadCallHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save feedback: ${result['message']}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_showHistory && _callHistory.isNotEmpty) _buildCallHistorySection(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.search, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toll-Free Search',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search by TMID or Mobile',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TollFreeHistoryScreen(),
                ),
              );
            },
            icon: Icon(Icons.history, color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter TMID or Mobile Number',
                prefixIcon: Icon(Icons.search, color: AppTheme.gray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.gray.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.gray.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray,
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSearching ? null : _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_searchResult != null) {
      return _buildUserCard(_searchResult!);
    }

    return _buildEmptyState();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: AppTheme.gray),
            const SizedBox(height: 16),
            Text('Search for a user', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Enter TMID or mobile number to find user details',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(TollFreeUser user) {
    // Get registration date
    String registrationDate = 'N/A';
    final payment = user.latestPayment;
    if (payment != null && payment['created_at'] != null) {
      try {
        final createdAt = DateTime.parse(payment['created_at'].toString());
        registrationDate = DateFormat('dd MMM yyyy').format(createdAt);
      } catch (e) {
        registrationDate = DateFormat('dd MMM yyyy').format(DateTime.now());
      }
    } else {
      registrationDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    }

    // Get state from TMID
    String state = StateCodeMapper.getStateName(user.uniqueId);

    // Parse profile completion percentage
    int profileCompletionPercentage = 0;
    if (user.profileCompletion != null) {
      try {
        profileCompletionPercentage = int.parse(
          user.profileCompletion!.replaceAll('%', ''),
        );
      } catch (e) {
        profileCompletionPercentage = 0;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _showFullDetails(user),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            children: [
              // Top Row: Avatar, Name, Call Button
              Row(
                children: [
                  // Avatar with profile completion
                  ProfileCompletionAvatar(
                    name: user.name,
                    userId: user.id,
                    userType: user.role,
                    completionPercentage: profileCompletionPercentage,
                    size: 54,
                    profileImageUrl: user.profileImage,
                    tmId: user.uniqueId,
                  ),
                  const SizedBox(width: 14),

                  // Name (Long press to copy)
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: user.name));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Name copied: ${user.name}'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(8),
                          ),
                        );
                        HapticFeedback.mediumImpact();
                      },
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Call Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _makeCall(user);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Divider
              Container(height: 1, color: Colors.grey.shade200),

              const SizedBox(height: 14),

              // Bottom Grid: Details in 2x2 layout
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today_outlined,
                      'Registration',
                      registrationDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on_outlined,
                      'State',
                      state,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildSubscriptionItem(user)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.badge_outlined,
                      'TMID',
                      user.uniqueId,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied: $value'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
          ),
        );
        HapticFeedback.mediumImpact();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.copy, size: 12, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(TollFreeUser user) {
    final payment = user.latestPayment;
    bool hasSubscription = user.hasSubscription;
    String subscriptionText = 'No Subscription';
    Color subscriptionColor = Colors.grey.shade600;

    if (hasSubscription && payment != null) {
      try {
        final startDate = DateTime.fromMillisecondsSinceEpoch(
          (payment['start_at'] as int) * 1000,
        );
        final endDate = DateTime.fromMillisecondsSinceEpoch(
          (payment['end_at'] as int) * 1000,
        );
        subscriptionText =
            '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
        subscriptionColor = const Color(0xFF4CAF50); // Green
      } catch (e) {
        subscriptionText = 'Active';
        subscriptionColor = const Color(0xFF4CAF50); // Green
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasSubscription
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 14,
              color: subscriptionColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: subscriptionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: subscriptionColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            subscriptionText,
            style: TextStyle(
              fontSize: 11,
              color: subscriptionColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showFullDetails(TollFreeUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TollFreeProfileDetailsScreen(user: user),
      ),
    );
  }

  Widget _buildCallHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Calls',
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_callHistory.length} call${_callHistory.length != 1 ? 's' : ''}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showHistory = !_showHistory;
                    });
                  },
                  icon: Icon(
                    _showHistory ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.gray,
                  ),
                ),
                IconButton(
                  onPressed: _loadCallHistory,
                  icon: Icon(
                    Icons.refresh,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),

          // Call History List
          if (_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _callHistory.length > 5 ? 5 : _callHistory.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final call = _callHistory[index];
                  return _buildCallHistoryItem(call);
                },
              ),
            ),

          // View All Button
          if (_callHistory.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TollFreeHistoryScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All (${_callHistory.length})',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(Map<String, dynamic> call) {
    final name = call['user_name'] ?? call['driver_name'] ?? 'Unknown';
    final mobile = call['user_mobile'] ?? call['user_number'] ?? '';
    final tmid = call['tmid'] ?? '';
    final feedback = call['feedback'] ?? 'No feedback';
    final callTime = call['call_time'] ?? '';
    final remarks = call['remarks'] ?? '';

    String formattedTime = 'N/A';
    if (callTime.isNotEmpty) {
      try {
        final date = DateTime.parse(callTime);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays == 0) {
          formattedTime = DateFormat('hh:mm a').format(date);
        } else if (difference.inDays == 1) {
          formattedTime = 'Yesterday';
        } else if (difference.inDays < 7) {
          formattedTime = '${difference.inDays} days ago';
        } else {
          formattedTime = DateFormat('dd MMM').format(date);
        }
      } catch (e) {
        formattedTime = callTime;
      }
    }

    Color feedbackColor = AppTheme.gray;
    IconData feedbackIcon = Icons.phone;

    if (feedback.toLowerCase().contains('connected') ||
        feedback.toLowerCase().contains('interested')) {
      feedbackColor = AppTheme.success;
      feedbackIcon = Icons.check_circle;
    } else if (feedback.toLowerCase().contains('not interested')) {
      feedbackColor = AppTheme.error;
      feedbackIcon = Icons.cancel;
    } else if (feedback.toLowerCase().contains('callback') ||
        feedback.toLowerCase().contains('call back')) {
      feedbackColor = AppTheme.warning;
      feedbackIcon = Icons.schedule;
    } else if (feedback.toLowerCase().contains('not reachable')) {
      feedbackColor = AppTheme.gray;
      feedbackIcon = Icons.phone_missed;
    }

    return InkWell(
      onTap: () {
        // Show call details dialog
        _showCallDetailsDialog(call);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: feedbackColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                feedbackIcon,
                color: feedbackColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (tmid.isNotEmpty) ...[
                        Text(
                          tmid,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.gray,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 11,
                            color: feedbackColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDetailsDialog(Map<String, dynamic> call) {
    final name = call['user_name'] ?? call['driver_name'] ?? 'Unknown';
    final mobile = call['user_mobile'] ?? call['user_number'] ?? '';
    final tmid = call['tmid'] ?? '';
    final feedback = call['feedback'] ?? 'No feedback';
    final callTime = call['call_time'] ?? '';
    final remarks = call['remarks'] ?? '';
    final callStatus = call['call_status'] ?? '';

    String formattedTime = 'N/A';
    if (callTime.isNotEmpty) {
      try {
        final date = DateTime.parse(callTime);
        formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(date);
      } catch (e) {
        formattedTime = callTime;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.call, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Call Details',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Name', name),
              _buildDetailRow('TMID', tmid),
              _buildDetailRow('Mobile', mobile),
              _buildDetailRow('Feedback', feedback),
              _buildDetailRow('Status', callStatus),
              _buildDetailRow('Time', formattedTime),
              if (remarks.isNotEmpty) _buildDetailRow('Remarks', remarks),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.gray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
