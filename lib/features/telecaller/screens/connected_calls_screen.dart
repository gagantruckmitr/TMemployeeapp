import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../core/services/toll_free_service.dart';
import '../../../models/toll_free_models.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/tab_page_header.dart';

const Map<String, String> _tollFreeProfileFields = {
  'city': 'City',
  'states': 'State Code',
  'pincode': 'Pincode',
  'address': 'Address',
  'Sex': 'Gender',
  'vehicle_type': 'Vehicle Type',
  'Father_Name': 'Father Name',
  'DOB': 'Date of Birth',
  'Marital_Status': 'Marital Status',
  'Highest_Education': 'Highest Education',
  'Driving_Experience': 'Driving Experience',
  'Type_of_License': 'Type of License',
  'License_Number': 'License Number',
  'Expiry_date_of_License': 'License Expiry',
  'Preferred_Location': 'Preferred Location',
  'Current_Monthly_Income': 'Current Monthly Income',
  'Expected_Monthly_Income': 'Expected Monthly Income',
  'Aadhar_Number': 'Aadhar Number',
  'job_placement': 'Job Placement',
  'previous_employer': 'Previous Employer',
  'Transport_Name': 'Transport Name',
  'Fleet_Size': 'Fleet Size',
  'Average_KM': 'Average KM',
  'PAN_Number': 'PAN Number',
  'GST_Number': 'GST Number',
  'PAN_Image': 'PAN Document',
  'GST_Certificate': 'GST Certificate',
  'Aadhar_Photo': 'Aadhar Document',
  'Driving_License': 'Driving License Document',
  'images': 'Profile Photo',
  'Training_Institute_Name': 'Training Institute Name',
  'Number_of_Seats_Available': 'Seats Available',
  'Monthly_Turnout': 'Monthly Turnout',
  'Language_of_Training': 'Training Language',
  'Placement_Candidates': 'Placement Candidates',
  'Pay_Scale': 'Pay Scale',
  'Referral_Code': 'Referral Code',
};

class ConnectedCallsScreen extends StatefulWidget {
  const ConnectedCallsScreen({super.key});

  @override
  State<ConnectedCallsScreen> createState() => _ConnectedCallsScreenState();
}

class _ConnectedCallsScreenState extends State<ConnectedCallsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<DriverContact>? _connectedContacts;
  List<DriverContact>? _filteredContacts;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isRefreshing = false;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  TollFreeContactDetail? _remoteSearchResult;
  bool _isRemoteSearching = false;
  String? _lastRemoteQuery;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _loadConnectedContactsAsync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _loadConnectedContactsAsync() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Force refresh to get latest data
      final contacts = await SmartCallingService.instance.getDriversByCategory(
        NavigationSection.connectedCalls,
      );

      if (mounted) {
        setState(() {
          _connectedContacts = contacts;
          _filteredContacts = _applySearchFilter(_searchQuery);
          _isLoading = false;
        });
        final rawQuery = _searchController.text.trim();
        if (_shouldFetchRemote(rawQuery, _filteredContacts ?? [])) {
          _fetchTollFreeContact(rawQuery);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectedContacts = [];
          _filteredContacts = [];
          _isLoading = false;
        });
      }
    }
  }

  List<DriverContact> _applySearchFilter(String query) {
    final source = _connectedContacts ?? [];
    if (query.isEmpty) {
      return List<DriverContact>.from(source);
    }

    final normalizedQuery = query.toLowerCase();
    final digitsOnly = query.replaceAll(RegExp(r'[^0-9]'), '');

    return source.where((contact) {
      final name = contact.name.toLowerCase();
      final tmid = contact.tmid.toLowerCase();
      final phone = contact.phoneNumber.toLowerCase();
      final company = contact.company.toLowerCase();

      final matchesText =
          name.contains(normalizedQuery) ||
          tmid.contains(normalizedQuery) ||
          company.contains(normalizedQuery);
      final matchesNumber = digitsOnly.isNotEmpty && phone.contains(digitsOnly);

      return matchesText || matchesNumber;
    }).toList();
  }

  void _onSearchChanged() {
    final rawQuery = _searchController.text.trim();
    final normalizedQuery = rawQuery.toLowerCase();
    final filtered = _applySearchFilter(normalizedQuery);

    setState(() {
      _searchQuery = normalizedQuery;
      _filteredContacts = filtered;
    });

    if (_shouldFetchRemote(rawQuery, filtered)) {
      _fetchTollFreeContact(rawQuery);
    } else {
      if (_remoteSearchResult != null || _isRemoteSearching) {
        setState(() {
          _remoteSearchResult = null;
          _isRemoteSearching = false;
          _lastRemoteQuery = null;
        });
      }
    }
  }

  bool _shouldFetchRemote(String rawQuery, List<DriverContact> filtered) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return false;
    if (filtered.isNotEmpty) return false;
    return trimmed.length >= 4;
  }

  Future<void> _fetchTollFreeContact(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final cacheKey = trimmed.toUpperCase();
    if (_lastRemoteQuery == cacheKey) return;
    _lastRemoteQuery = cacheKey;

    setState(() {
      _isRemoteSearching = true;
      _remoteSearchResult = null;
    });

    try {
      final result = await TollFreeService.instance.search(cacheKey);
      if (!mounted || _lastRemoteQuery != cacheKey) return;
      setState(() {
        _remoteSearchResult = result;
        _isRemoteSearching = false;
      });
    } catch (e) {
      if (!mounted || _lastRemoteQuery != cacheKey) return;
      setState(() {
        _remoteSearchResult = null;
        _isRemoteSearching = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Clear cache and fetch fresh data
      SmartCallingService.instance.clearCache();
      final contacts = await SmartCallingService.instance.getDriversByCategory(
        NavigationSection.connectedCalls,
      );

      if (mounted) {
        setState(() {
          _connectedContacts = contacts;
          _isRefreshing = false;
          _filteredContacts = _applySearchFilter(_searchQuery);
        });
        final rawQuery = _searchController.text.trim();
        if (_shouldFetchRemote(rawQuery, _filteredContacts ?? [])) {
          _fetchTollFreeContact(rawQuery);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onCallPressed(DriverContact contact) {
    HapticFeedback.mediumImpact();
    _showCallFeedbackModal(contact);
  }

  void _showCallFeedbackModal(DriverContact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CallFeedbackModal(
            contact: contact,
            onFeedbackSubmitted: (feedback) {
              _handleFeedbackSubmitted(contact, feedback);
              Navigator.of(context).pop();
            },
          ),
    );
  }

  Future<void> _handleFeedbackSubmitted(
    DriverContact contact,
    CallFeedback feedback,
  ) async {
    // Update via API
    final success = await SmartCallingService.instance.updateCallStatus(
      driverId: contact.id,
      status: feedback.status,
      feedback: _getFeedbackText(feedback),
      remarks: feedback.remarks,
    );

    if (success) {
      // Refresh the list to get updated data
      await _refreshData();

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${contact.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getFeedbackText(CallFeedback feedback) {
    if (feedback.connectedFeedback != null) {
      return feedback.connectedFeedback!.displayName;
    } else if (feedback.callBackReason != null) {
      return feedback.callBackReason!.displayName;
    } else if (feedback.callBackTime != null) {
      return feedback.callBackTime!.displayName;
    }
    return feedback.status.name;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final totalConnections = _connectedContacts?.length ?? 0;
    final remoteDetail = _remoteSearchResult;
    final baseContacts =
        _filteredContacts ?? (_connectedContacts ?? <DriverContact>[]);
    final List<DriverContact> contactsToDisplay = List<DriverContact>.from(
      baseContacts,
    );

    if (remoteDetail != null) {
      final exists = contactsToDisplay.any(
        (contact) =>
            contact.phoneNumber == remoteDetail.driver.phoneNumber ||
            contact.tmid == remoteDetail.driver.tmid,
      );
      if (!exists) {
        contactsToDisplay.insert(0, remoteDetail.driver);
      }
    }

    final isEmptyState = contactsToDisplay.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          TelecallerTabHeader(
            icon: Icons.phone_rounded,
            iconColor: Colors.green.shade600,
            title: 'Toll Free Calls',
            subtitle: '$totalConnections successful connections',
            trailing: TelecallerHeaderActionButton(
              isLoading: _isRefreshing,
              onPressed: _refreshData,
              icon: Icons.refresh_rounded,
              color: Colors.green.shade600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade500,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.grey.shade500,
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                          : _isRemoteSearching
                          ? Padding(
                            padding: const EdgeInsets.only(
                              right: 12,
                              top: 12,
                              bottom: 12,
                            ),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade600,
                                ),
                              ),
                            ),
                          )
                          : null,
                  hintText: 'Search by name, TM ID, or number',
                  hintStyle: AppTheme.bodyLarge.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const _LoadingWidget()
                    : RefreshIndicator(
                      onRefresh: _refreshData,
                      child:
                          isEmptyState
                              ? const _EmptyStateWidget()
                              : _ContactsList(
                                contacts: contactsToDisplay,
                                scrollController: _scrollController,
                                onCallPressed: _onCallPressed,
                                onContactTap: (contact) {
                                  if (remoteDetail != null &&
                                      contact.tmid ==
                                          remoteDetail.driver.tmid) {
                                    _showRemoteDetail(remoteDetail);
                                  } else {
                                    _showContactDetail(contact);
                                  }
                                },
                              ),
                    ),
          ),
        ],
      ),
    );
  }

  void _showContactDetail(DriverContact contact) async {
    // Fetch full details from API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detail = await TollFreeService.instance.search(contact.tmid);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (detail != null) {
        _showRemoteDetail(detail);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load full details'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading details: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRemoteDetail(TollFreeContactDetail detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final driver = detail.driver;
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primaryBlue
                                    .withOpacity(0.12),
                                child: Text(
                                  driver.name.isNotEmpty
                                      ? driver.name[0].toUpperCase()
                                      : 'T',
                                  style: AppTheme.headingMedium.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.name,
                                      style: AppTheme.headingMedium.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      driver.tmid,
                                      style: AppTheme.bodyLarge.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            title: 'Contact Information',
                            rows: [
                              _InfoRow(
                                icon: Icons.call,
                                label: 'Mobile',
                                value: driver.phoneNumber,
                                copyable: true,
                              ),
                              if (detail.email != null &&
                                  detail.email!.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: detail.email!,
                                  copyable: true,
                                ),
                              _InfoRow(
                                icon: Icons.language_outlined,
                                label: 'Language',
                                value: detail.language ?? 'Not specified',
                              ),
                              _InfoRow(
                                icon: Icons.location_pin,
                                label: 'State',
                                value: detail.stateName ?? driver.state,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            title: 'User Information',
                            rows: _buildUserInfoRows(detail),
                          ),
                          if (detail.latestPayment != null) ...[
                            const SizedBox(height: 20),
                            _buildDetailSection(
                              title: 'Payment Information',
                              rows: _buildPaymentRows(detail.latestPayment!),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            title: 'Profile & Subscription',
                            rows: _buildProfileSubscriptionRows(detail),
                          ),
                          const SizedBox(height: 20),
                          _buildProfileDocuments(detail),
                          if (detail.appliedJobs.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildJobsSection(detail.appliedJobs),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _copyText(driver.phoneNumber);
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Number'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _onCallPressed(driver);
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Call Driver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  List<Widget> _buildProfileSubscriptionRows(TollFreeContactDetail detail) {
    final driver = detail.driver;
    final payment = detail.latestPayment;
    
    return [
      _InfoRow(
        icon: Icons.calendar_today,
        label: 'Registered On',
        value:
            driver.registrationDate != null
                ? _formatDate(driver.registrationDate!)
                : 'Not available',
      ),
      _InfoRow(
        icon: Icons.schedule,
        label: 'Paid On',
        value:
            payment?.createdAt != null
                ? _formatDate(payment!.createdAt!)
                : 'N/A',
      ),
      _InfoRow(
        icon: Icons.event_available,
        label: 'Valid Till',
        value:
            payment?.expiryDate != null
                ? _formatDate(payment!.expiryDate!)
                : 'N/A',
      ),
    ];
  }

  Widget _buildProfileDocuments(TollFreeContactDetail detail) {
    final completedDocs = <_DocumentItem>[];
    final missingDocs = <_DocumentItem>[];
    final raw = detail.rawUserData;

    void addDocument(String key, String label) {
      final formattedValue =
          _formatProfileFieldValue(key, raw[key], detail).trim();
      final hasValue = formattedValue.isNotEmpty;
      final item = _DocumentItem(
        label: label,
        value: hasValue ? formattedValue : 'N/A',
        isComplete: hasValue,
      );
      if (hasValue) {
        completedDocs.add(item);
      } else {
        missingDocs.add(item);
      }
    }

    completedDocs.add(
      _DocumentItem(
        label: 'Basic Information',
        value: detail.driver.name,
        isComplete: true,
      ),
    );
    if (detail.email != null && detail.email!.trim().isNotEmpty) {
      completedDocs.add(
        _DocumentItem(label: 'Email', value: detail.email!, isComplete: true),
      );
    } else {
      missingDocs.add(
        const _DocumentItem(label: 'Email', value: 'N/A', isComplete: false),
      );
    }

    if (detail.driver.phoneNumber.isNotEmpty) {
      completedDocs.add(
        _DocumentItem(
          label: 'Mobile',
          value: detail.driver.phoneNumber,
          isComplete: true,
        ),
      );
    }

    _tollFreeProfileFields.forEach(addDocument);

    final totalDocs = completedDocs.length + missingDocs.length;
    final completionLabel = detail.profileCompletionLabel ?? '0%';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Completion',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                child: Text(
                  completionLabel,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$completionLabel Complete',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${completedDocs.length}/$totalDocs documents',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentList(
            title: 'Completed Documents (${completedDocs.length})',
            icon: Icons.check_circle,
            iconColor: Colors.green.shade600,
            items: completedDocs,
          ),
          const SizedBox(height: 16),
          _buildDocumentList(
            title: 'Missing Documents (${missingDocs.length})',
            icon: Icons.radio_button_unchecked,
            iconColor: Colors.red.shade500,
            items: missingDocs,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_DocumentItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No entries',
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey.shade500),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.isComplete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        item.isComplete
                            ? Colors.green.shade600
                            : Colors.red.shade500,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item.value,
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
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

  String _formatProfileFieldValue(
    String key,
    dynamic value,
    TollFreeContactDetail detail,
  ) {
    if (key == 'states') {
      return detail.stateName ?? '';
    }

    if (value == null) return '';
    String str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return '';

    switch (key) {
      case 'Aadhar_Photo':
      case 'Driving_License':
      case 'PAN_Image':
      case 'GST_Certificate':
      case 'images':
        return 'Uploaded';
      default:
        return str;
    }
  }

  Widget _buildJobsSection(List<TollFreeJobApplication> jobs) {
    return _buildDetailSection(
      title: 'Applied Jobs',
      rows:
          jobs
              .map(
                (job) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle ?? 'Job',
                          style: AppTheme.headingMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (job.jobId != null && job.jobId!.isNotEmpty)
                          _InlineDetail(
                            icon: Icons.badge_outlined,
                            text: 'Job ID: ${job.jobId!}',
                          ),
                        if (job.transporterId != null && job.transporterId!.isNotEmpty)
                          _InlineDetail(
                            icon: Icons.business_outlined,
                            text: 'Transporter ID: ${job.transporterId!}',
                          ),
                        if (job.location != null && job.location!.isNotEmpty)
                          _InlineDetail(
                            icon: Icons.location_on_outlined,
                            text: job.location!,
                          ),
                        if (job.salaryRange != null &&
                            job.salaryRange!.isNotEmpty)
                          _InlineDetail(
                            icon: Icons.currency_rupee,
                            text: job.salaryRange!,
                          ),
                        if (job.requiredExperience != null &&
                            job.requiredExperience!.isNotEmpty)
                          _InlineDetail(
                            icon: Icons.work_outline,
                            text: 'Experience: ${job.requiredExperience!}',
                          ),
                        if (job.applicationDeadline != null)
                          _InlineDetail(
                            icon: Icons.calendar_today_outlined,
                            text:
                                'Deadline: ${_formatDate(job.applicationDeadline!)}',
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $text'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthLabel(date.month)} '
        '${date.year}';
  }

  String _monthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  List<Widget> _buildUserInfoRows(TollFreeContactDetail detail) {
    final raw = detail.rawUserData;
    return [
      _InfoRow(
        icon: Icons.badge_outlined,
        label: 'User ID',
        value: _formatDisplayValue(raw['id']),
      ),
      _InfoRow(
        icon: Icons.person_outline,
        label: 'Role',
        value: _formatDisplayValue(raw['role']),
      ),
      _InfoRow(
        icon: Icons.verified_user_outlined,
        label: 'Status',
        value: _formatStatus(raw['status']),
      ),
      _InfoRow(
        icon: Icons.assignment_ind_outlined,
        label: 'Assigned To',
        value: _formatAssigned(raw['assigned_to']),
      ),
      _InfoRow(
        icon: Icons.language,
        label: 'User Language',
        value: detail.language ?? _formatDisplayValue(raw['user_lang']),
      ),
      _InfoRow(
        icon: Icons.event_note_outlined,
        label: 'Created',
        value: _formatDateTimeValue(raw['Created_at']),
      ),
      _InfoRow(
        icon: Icons.update,
        label: 'Updated',
        value: _formatDateTimeValue(raw['Updated_at']),
      ),
      _InfoRow(
        icon: Icons.percent,
        label: 'Driver Completion',
        value: _formatPercentage(raw['driver_completion']),
      ),
    ];
  }

  List<Widget> _buildPaymentRows(TollFreePaymentDetail payment) {
    return [
      _InfoRow(
        icon: Icons.play_circle_outline,
        label: 'Started On',
        value: _formatDateTimeValue(payment.startDate),
      ),
      _InfoRow(
        icon: Icons.schedule,
        label: 'Paid On',
        value: _formatDateTimeValue(payment.createdAt),
      ),
      _InfoRow(
        icon: Icons.event_available,
        label: 'Valid Till',
        value: _formatDateTimeValue(payment.expiryDate),
      ),
    ];
  }

  String _formatDisplayValue(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return 'N/A';
    return text;
  }

  String _formatPercentage(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return 'N/A';
    if (text.endsWith('%')) return text;
    return '$text%';
  }

  String _formatStatus(dynamic value) {
    final text = _formatDisplayValue(value);
    switch (text) {
      case '1':
        return 'Active';
      case '0':
        return 'Inactive';
      default:
        return text;
    }
  }

  String _formatAssigned(dynamic value) {
    if (value == null) return 'Not assigned';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return 'Not assigned';
    }
    return text;
  }

  String _formatDateTimeValue(dynamic value) {
    final dateTime = _tryParseDate(value);
    if (dateTime == null) return 'N/A';
    final timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '${_formatDate(dateTime)} $timeString';
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value * 1000,
        isUtc: true,
      ).toLocal();
    }
    if (value is String) {
      if (value.isEmpty || value.toLowerCase() == 'null') return null;
      final normalized =
          value.contains('T') ? value : value.replaceAll(' ', 'T');
      return DateTime.tryParse(normalized);
    }
    return null;
  }
}

class _ContactsList extends StatelessWidget {
  final List<DriverContact> contacts;
  final ScrollController scrollController;
  final Function(DriverContact) onCallPressed;
  final ValueChanged<DriverContact>? onContactTap;

  const _ContactsList({
    required this.contacts,
    required this.scrollController,
    required this.onCallPressed,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DriverContactCard(
            key: ValueKey(contact.id),
            contact: contact,
            onCallPressed: () => onCallPressed(contact),
            onTap: onContactTap != null ? () => onContactTap!(contact) : null,
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: AppTheme.bodyLarge.copyWith(
                          color: valueColor ?? AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (copyable)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        color: Colors.grey.shade500,
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied $value'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineDetail extends StatelessWidget {
  const _InlineDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem {
  const _DocumentItem({
    required this.label,
    required this.value,
    required this.isComplete,
  });

  final String label;
  final String value;
  final bool isComplete;
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.phone_disabled_rounded,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Connected Calls',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Successfully connected calls\nwill appear here',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
