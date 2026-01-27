import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/real_auth_service.dart';
import '../../../core/services/smart_calling_service.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/call_feedback_modal.dart';
import '../widgets/transporter_feedback_modal.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/ivr_call_waiting_overlay.dart';
import '../widgets/search_filter_sheet.dart';
import 'toll_free_history_screen.dart';

class TollFreeSearchScreen extends StatefulWidget {
  const TollFreeSearchScreen({super.key});

  @override
  State<TollFreeSearchScreen> createState() => _TollFreeSearchScreenState();
}

class _TollFreeSearchScreenState extends State<TollFreeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<DriverContact> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _errorMessage = '';
  SearchFilters _filters = SearchFilters();

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    // Allow search with filters even if query is empty
    if (query.trim().isEmpty && !_filters.hasActiveFilters) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
    });

    try {
      // Get bearer token from login session
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Please login again to search users';
          _isLoading = false;
        });
        return;
      }

      // Build URL with search query - same API as search_users_screen
      final uri = Uri.parse(
        'https://truckmitr.com/api/telehead/payments/search',
      ).replace(queryParameters: {'search': query.trim()});

      debugPrint('🔍 [TollFree] Searching users: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 [TollFree] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> usersJson = data['users'] ?? [];

          debugPrint('✅ [TollFree] Found ${usersJson.length} users');

          setState(() {
            _searchResults = usersJson
                .map((json) => DriverContact.fromBacklogJson(json))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to search users';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [TollFree] Search error: $e');
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _makeCall(DriverContact contact) async {
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

      // Clean phone numbers
      final telecallerPhone = currentUser.mobile.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final cleanUserMobile = contact.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      debugPrint(
        '📞 [TollFree] Initiating Live IVR call - Telecaller: $telecallerPhone, User: ${contact.name}, Mobile: $cleanUserMobile',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📞 Initiating Live IVR call to ${contact.name}...'),
          backgroundColor: AppTheme.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Use Live IVR API via SmartCallingService
      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanUserMobile,
        callerId: currentUser.id,
        contactId: contact.id,
        tmid: contact.tmid,
        contactType: contact.role == 'transporter' ? 'transporter' : 'driver',
        driverName: contact.name,
        callSource: 'toll-free',
        process:
            'tollfree', // Set process to 'tollfree' for Toll Free Search screen
      );

      debugPrint('🔔 [TollFree] Live IVR Result: $result');

      if (!mounted) return;

      if (result['success'] == true) {
        final referenceId =
            result['reference_id'] ??
            result['call_id']?.toString() ??
            result['data']?['call_id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        debugPrint('✅ [TollFree] Live IVR initiated! Ref: $referenceId');

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Live IVR call initiated! Both phones will ring.\n'
              'Answer either phone to connect.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Show IVR waiting overlay (same as smart_calling_page.dart)
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (overlayContext) => PopScope(
              canPop: false,
              child: IVRCallWaitingOverlay(
                driverName: contact.name,
                referenceId: referenceId,
                onCallEnded: () {
                  // NOTE: Do NOT pop here - the IVRCallWaitingOverlay button
                  // already pops itself before calling this callback

                  // Add a small delay to ensure the pop animation completes
                  // before showing the feedback modal
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      _showFeedbackModal(
                        contact,
                        referenceId: referenceId,
                        callDuration: 0,
                        isLiveEasyGo: true,
                      );
                    }
                  });
                },
              ),
            ),
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        final errorMsg = result['error'] ?? 'Unknown error';
        debugPrint('❌ [TollFree] Live IVR failed: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Call failed: $errorMsg'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      debugPrint('❌ [TollFree] Live IVR error: $error');
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

  void _showFeedbackModal(
    DriverContact contact, {
    String? referenceId,
    int? callDuration,
    bool isLiveEasyGo = false,
  }) {
    // Check if user is a transporter
    final isTransporter = contact.role?.toLowerCase() == 'transporter';

    if (isTransporter) {
      // Show transporter feedback modal
      final transporterContact = TransporterContact(
        id: contact.id,
        tmid: contact.tmid,
        name: contact.name,
        company: contact.company,
        phoneNumber: contact.phoneNumber,
        state: contact.state,
        subscriptionStatus: contact.subscriptionStatus,
        status: contact.status,
        lastFeedback: contact.lastFeedback,
        lastCallTime: contact.lastCallTime,
        remarks: contact.remarks,
        paymentInfo: contact.paymentInfo,
        registrationDate: contact.registrationDate,
        profileCompletion: contact.profileCompletion,
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (modalContext) => TransporterFeedbackModal(
          contact: transporterContact,
          referenceId: referenceId,
          callDuration: callDuration,
          onFeedbackSubmitted: (feedback) async {
            debugPrint(
              '🔵 [TollFree] Transporter feedback modal callback triggered',
            );

            try {
              await _handleFeedbackSubmitted(
                contact,
                feedback,
                referenceId: referenceId,
                isLiveEasyGo: isLiveEasyGo,
              );
              debugPrint('🔵 [TollFree] Transporter feedback update completed');
            } catch (e) {
              debugPrint(
                '❌ [TollFree] Exception during transporter feedback update: $e',
              );
            } finally {
              debugPrint(
                '🔵 [TollFree] Closing transporter feedback modal (guaranteed)',
              );
              if (modalContext.mounted) {
                Navigator.of(modalContext).pop();
              }
            }
          },
        ),
      );
    } else {
      // Show driver feedback modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (modalContext) => CallFeedbackModal(
          contact: contact,
          referenceId: referenceId,
          callDuration: callDuration,
          allowDismiss: true,
          onFeedbackSubmitted: (feedback) async {
            debugPrint(
              '🔵 [TollFree] Driver feedback modal callback triggered',
            );

            try {
              await _handleFeedbackSubmitted(
                contact,
                feedback,
                referenceId: referenceId,
                isLiveEasyGo: isLiveEasyGo,
              );
              debugPrint('🔵 [TollFree] Driver feedback update completed');
            } catch (e) {
              debugPrint(
                '❌ [TollFree] Exception during driver feedback update: $e',
              );
            } finally {
              debugPrint(
                '🔵 [TollFree] Closing driver feedback modal (guaranteed)',
              );
              if (modalContext.mounted) {
                Navigator.of(modalContext).pop();
              }
            }
          },
        ),
      );
    }
  }

  // Map CallStatus enum to database format
  String _mapCallStatusToDb(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return 'connected';
      case CallStatus.callBack:
        return 'not_connected';
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_connected';
      case CallStatus.notInterested:
        return 'connected';
      case CallStatus.invalid:
        return 'not_connected';
      case CallStatus.pending:
        return 'not_connected';
    }
  }

  Future<void> _handleFeedbackSubmitted(
    DriverContact contact,
    CallFeedback feedback, {
    String? referenceId,
    bool isLiveEasyGo = false,
  }) async {
    if (!mounted) return;

    // Prepare feedback text
    String feedbackText = '';
    switch (feedback.status) {
      case CallStatus.connected:
        // Check for transporter feedback first, then driver feedback
        if (feedback.transporterConnectedFeedback != null) {
          feedbackText = feedback.transporterConnectedFeedback!.displayName;
        } else if (feedback.connectedFeedback != null) {
          feedbackText = feedback.connectedFeedback!.displayName;
        } else {
          feedbackText = 'Connected';
        }
        break;
      case CallStatus.callBack:
        feedbackText = feedback.callBackReason?.displayName ?? 'Call Back';
        break;
      case CallStatus.callBackLater:
        feedbackText = feedback.callBackTime?.displayName ?? 'Call Back Later';
        break;
      case CallStatus.notReachable:
        feedbackText = 'Not Reachable';
        break;
      case CallStatus.notInterested:
        feedbackText = 'Not Interested';
        break;
      case CallStatus.invalid:
        feedbackText = 'Invalid Number';
        break;
      case CallStatus.pending:
        feedbackText = 'Pending';
        break;
    }

    bool success = false;

    // Use Live EasyGo IVR Feedback API if isLiveEasyGo is true
    if (isLiveEasyGo && referenceId != null) {
      debugPrint(
        '🔵 [TollFree] Updating Live EasyGo Feedback: ref=$referenceId, status=${feedback.status}',
      );

      final callId = int.tryParse(referenceId);
      if (callId != null) {
        String dbStatus = _mapCallStatusToDb(feedback.status);

        success = await SmartCallingService.instance.updateEasyGoCallFeedback(
          callId: callId,
          status: dbStatus,
          feedback: feedbackText,
          remarks: feedback.remarks,
          recordingFile: feedback.recordingFile?.path,
        );

        debugPrint(
          '🔵 [TollFree] Live EasyGo Feedback update result: ${success ? "SUCCESS" : "FAILED"}',
        );
      } else {
        debugPrint(
          '❌ [TollFree] Invalid call ID for EasyGo Update: $referenceId',
        );
      }
    }

    if (!mounted) return;

    HapticFeedback.lightImpact();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Feedback saved for ${contact.name}'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear search after feedback
      setState(() {
        _searchResults = [];
        _searchController.clear();
        _hasSearched = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save feedback for ${contact.name}'),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button for tab screens
        title: Text(
          'Search and Call',
          style: AppTheme.headingMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.black87),
                onPressed: _showFilterSheet,
              ),
              if (_filters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_filters.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by phone, TMID, email, city...',
                hintStyle: AppTheme.bodyLarge.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {}); // Update UI for clear button
              },
              onSubmitted: _performSearch,
            ),
          ),

          // Results Count
          if (_hasSearched && !_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    '${_searchResults.length} results found',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'Tap to call',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _performSearch(_searchController.text),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Search & Call',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for drivers and transporters\nby name, phone, email, city or TMID',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final contact = _searchResults[index];
        return DriverContactCard(
          contact: contact,
          onCallPressed: () => _makeCall(contact),
          isCallInProgress: false,
          showPhoneNumber: true,
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SearchFilterSheet(
          initialFilters: _filters,
          onApply: (filters) {
            setState(() {
              _filters = filters;
            });
            // Re-run search with new filters (even if search query is empty)
            if (filters.hasActiveFilters || _searchController.text.isNotEmpty) {
              _performSearch(_searchController.text);
            }
          },
        ),
      ),
    );
  }
}
