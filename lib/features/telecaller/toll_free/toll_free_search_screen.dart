import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/toll_free_service.dart';
import '../../../core/services/toll_free_feedback_service.dart';
import '../../../models/toll_free_lead_model.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/utils/state_code_mapper.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/profile_completion_avatar.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final callType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📞 Select Call Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how to call ${user.name}:',
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.phone, color: AppTheme.success),
                title: const Text('Manual Call'),
                subtitle: const Text('Direct phone dialer'),
                onTap: () => Navigator.pop(context, 'manual'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.success),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (callType == null || !mounted) return;

      final cleanNumber = user.mobile.replaceAll(RegExp(r'[^\d]'), '');

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📱 Calling ${user.name}...'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      await FlutterPhoneDirectCaller.callNumber(cleanNumber);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showFeedbackModal(user);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $error'),
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

      // Clear search after feedback
      setState(() {
        _searchResult = null;
        _searchController.clear();
      });
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
                    completionPercentage: profileCompletionPercentage,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showFullDetails(user);
                    },
                    size: 54,
                    imageUrl: user.profileImage,
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

  void _showFullDetailsOld(TollFreeUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                      Expanded(
                        child: Text(
                          'Full Details',
                          style: AppTheme.headingMedium.copyWith(
                            fontSize: 20,
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
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Section
                        _buildSection('User Information', [
                          _buildInfoTile('Name', user.name),
                          _buildInfoTile('TMID', user.uniqueId),
                          _buildInfoTile('Mobile', user.mobile),
                          if (user.email != null)
                            _buildInfoTile('Email', user.email!),
                          _buildInfoTile('Role', user.role.toUpperCase()),
                          if (user.profileCompletion != null)
                            _buildInfoTile(
                              'Profile Completion',
                              user.profileCompletion!,
                            ),
                        ]),

                        // Subscription Section
                        _buildSection('Subscription', [
                          _buildInfoTile(
                            'Status',
                            user.hasSubscription ? 'Active ✓' : 'Inactive',
                            valueColor: user.hasSubscription
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ]),

                        // Payment Details Section
                        if (user.latestPayment != null) ...[
                          _buildSection('Payment Details', []),
                          Builder(
                            builder: (context) {
                              final payment = user.latestPayment!;
                              final startAt = payment['start_at'] as int?;
                              final endAt = payment['end_at'] as int?;
                              final amount = payment['amount'] ?? 'N/A';
                              final paymentStatus =
                                  payment['payment_status'] ?? 'N/A';

                              String startDate = 'N/A';
                              String endDate = 'N/A';

                              if (startAt != null) {
                                startDate = DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        startAt * 1000,
                                      ),
                                    );
                              }

                              if (endAt != null) {
                                endDate = DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        endAt * 1000,
                                      ),
                                    );
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.success.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.payment,
                                          color: AppTheme.success,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹$amount',
                                          style: AppTheme.headingMedium
                                              .copyWith(
                                                color: AppTheme.success,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: paymentStatus == 'captured'
                                                ? AppTheme.success.withOpacity(
                                                    0.2,
                                                  )
                                                : AppTheme.warning.withOpacity(
                                                    0.2,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            paymentStatus
                                                .toString()
                                                .toUpperCase(),
                                            style: AppTheme.bodySmall.copyWith(
                                              color: paymentStatus == 'captured'
                                                  ? AppTheme.success
                                                  : AppTheme.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    _buildInfoTile(
                                      'Payment ID',
                                      payment['payment_id'] ?? 'N/A',
                                    ),
                                    _buildInfoTile(
                                      'Order ID',
                                      payment['order_id'] ?? 'N/A',
                                    ),
                                    _buildInfoTile(
                                      'Payment Type',
                                      payment['payment_type'] ?? 'N/A',
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: AppTheme.gray,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Subscription Period',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.gray,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.play_arrow,
                                                size: 16,
                                                color: AppTheme.success,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Start Date',
                                                      style: AppTheme.bodySmall
                                                          .copyWith(
                                                            color:
                                                                AppTheme.gray,
                                                          ),
                                                    ),
                                                    Text(
                                                      startDate,
                                                      style: AppTheme.bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 16),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.stop,
                                                size: 16,
                                                color: AppTheme.error,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'End Date',
                                                      style: AppTheme.bodySmall
                                                          .copyWith(
                                                            color:
                                                                AppTheme.gray,
                                                          ),
                                                    ),
                                                    Text(
                                                      endDate,
                                                      style: AppTheme.bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],

                        // Applied Jobs Section
                        if (user.appliedJobs.isNotEmpty) ...[
                          _buildSection(
                            'Applied Jobs (${user.appliedJobs.length})',
                            [],
                          ),
                          ...user.appliedJobs.map((job) {
                            final jobDetailsRaw = job['job_details'];
                            final jobDetails =
                                jobDetailsRaw is Map<String, dynamic>
                                ? jobDetailsRaw
                                : <String, dynamic>{};
                            final jobId = jobDetails['job_id'] ?? 'N/A';
                            final vehicleType =
                                jobDetails['vehicle_type'] ?? 'N/A';
                            final requiredExp =
                                jobDetails['Required_Experience'] ?? 'N/A';
                            final licenseType =
                                jobDetails['Type_of_License'] ?? 'N/A';
                            final deadline = jobDetails['Application_Deadline'];
                            final driversRequired =
                                jobDetails['number_of_drivers_required'] ??
                                'N/A';
                            final jobDescription =
                                jobDetails['Job_Description'] ?? '';

                            String formattedDeadline = 'N/A';
                            if (deadline != null) {
                              try {
                                formattedDeadline = DateFormat(
                                  'dd MMM yyyy',
                                ).format(DateTime.parse(deadline));
                              } catch (e) {
                                formattedDeadline = deadline.toString();
                              }
                            }

                            // Strip HTML tags from description
                            String cleanDescription = jobDescription
                                .replaceAll(RegExp(r'<[^>]*>'), '')
                                .replaceAll(RegExp(r'\r\n|\n|\r'), ' ')
                                .trim();
                            if (cleanDescription.length > 150) {
                              cleanDescription =
                                  '${cleanDescription.substring(0, 150)}...';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGray,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.gray.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          jobDetails['job_title'] ??
                                              'Job Application',
                                          style: AppTheme.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              job['accept_reject_status'] ==
                                                  'pending'
                                              ? AppTheme.warning.withOpacity(
                                                  0.2,
                                                )
                                              : AppTheme.success.withOpacity(
                                                  0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          (job['accept_reject_status'] ??
                                                  'pending')
                                              .toString()
                                              .toUpperCase(),
                                          style: AppTheme.bodySmall.copyWith(
                                            color:
                                                job['accept_reject_status'] ==
                                                    'pending'
                                                ? AppTheme.warning
                                                : AppTheme.success,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Job ID
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.badge,
                                        size: 14,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Job ID: ',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.gray,
                                        ),
                                      ),
                                      Text(
                                        jobId,
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Location
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: AppTheme.gray,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          jobDetails['job_location'] ?? 'N/A',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.gray,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Salary
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.currency_rupee,
                                        size: 14,
                                        color: AppTheme.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        jobDetails['Salary_Range'] ?? 'N/A',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Vehicle Type
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        size: 14,
                                        color: AppTheme.gray,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          vehicleType,
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.gray,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // License & Experience
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.card_membership,
                                        size: 14,
                                        color: AppTheme.gray,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$licenseType | $requiredExp years exp',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.gray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Drivers Required
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 14,
                                        color: AppTheme.gray,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$driversRequired drivers required',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.gray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Deadline
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: AppTheme.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Deadline: $formattedDeadline',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Description
                                  if (cleanDescription.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.description,
                                                size: 14,
                                                color: AppTheme.primaryBlue,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Description',
                                                style: AppTheme.bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppTheme.primaryBlue,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cleanDescription,
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.darkGray,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Applied Date
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: AppTheme.gray,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Applied: ${DateFormat('dd MMM yyyy').format(DateTime.parse(job['created_at']))}',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.gray,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],

                        // Call Logs Section
                        if (user.callLogs.isNotEmpty) ...[
                          _buildSection(
                            'Call History (${user.callLogs.length})',
                            [],
                          ),
                          ...user.callLogs.map((log) {
                            final callTime = log['call_time'] != null
                                ? DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(DateTime.parse(log['call_time']))
                                : 'N/A';
                            final status = log['status'] ?? 'N/A';
                            final feedback = log['feedback'] ?? 'No feedback';

                            Color statusColor = AppTheme.gray;
                            IconData statusIcon = Icons.phone;

                            switch (status.toLowerCase()) {
                              case 'connected':
                                statusColor = AppTheme.success;
                                statusIcon = Icons.phone_in_talk;
                                break;
                              case 'not connected':
                                statusColor = AppTheme.error;
                                statusIcon = Icons.phone_missed;
                                break;
                              case 'busy':
                                statusColor = AppTheme.warning;
                                statusIcon = Icons.phone_disabled;
                                break;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        statusIcon,
                                        color: statusColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          callTime,
                                          style: AppTheme.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: AppTheme.bodySmall.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (feedback != 'No feedback') ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.comment,
                                            size: 14,
                                            color: AppTheme.gray,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              feedback,
                                              style: AppTheme.bodySmall
                                                  .copyWith(
                                                    color: AppTheme.darkGray,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (log['remarks'] != null &&
                                      log['remarks'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.note,
                                            size: 14,
                                            color: AppTheme.gray,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              log['remarks'],
                                              style: AppTheme.bodySmall
                                                  .copyWith(
                                                    color: AppTheme.darkGray,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: AppTheme.headingMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.gray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyLarge.copyWith(
                color: valueColor ?? AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
