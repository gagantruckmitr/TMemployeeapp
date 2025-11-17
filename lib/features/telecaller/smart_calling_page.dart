import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/smart_calling_models.dart';
import '../../core/services/smart_calling_service.dart';
import '../../core/services/real_auth_service.dart';
import 'widgets/driver_contact_card.dart';
import 'widgets/call_feedback_modal.dart';
import 'widgets/call_type_selection_dialog.dart';
import 'widgets/ivr_call_waiting_overlay.dart';

class SmartCallingPage extends StatefulWidget {
  const SmartCallingPage({super.key});

  @override
  State<SmartCallingPage> createState() => _SmartCallingPageState();
}

class _SmartCallingPageState extends State<SmartCallingPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<DriverContact> _filteredContacts = [];
  List<DriverContact> _allContacts = [];
  bool _isLoading = true;
  bool _isCallInProgress = false;
  DriverContact? _currentCallingContact;

  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final drivers = await SmartCallingService.instance.getDrivers();

      if (mounted) {
        setState(() {
          _allContacts = drivers;
          _filteredContacts = List.from(_allContacts);
          _isLoading = false;
        });
        _slideAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load drivers: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_allContacts);
      } else {
        _filteredContacts = _allContacts
            .where(
              (contact) =>
                  contact.name.toLowerCase().contains(query.toLowerCase()) ||
                  contact.company.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _startCall(DriverContact contact) async {
    if (_isCallInProgress) return;

    setState(() {
      _isCallInProgress = true;
      _currentCallingContact = contact;
    });

    try {
      // Get current user ID BEFORE showing dialog
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ User not logged in. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isCallInProgress = false;
            _currentCallingContact = null;
          });
        }
        return;
      }

      final callerId = int.tryParse(currentUser.id) ?? 1;
      debugPrint(
        '🔵 Starting call - Caller ID: $callerId, Driver: ${contact.name} (${contact.phoneNumber})',
      );

      // Show modern call type selection dialog
      if (mounted) {
        final callType = await showDialog<String>(
          context: context,
          builder: (context) => CallTypeSelectionDialog(
            driverName: contact.name,
          ),
        );

        if (callType == null) {
          setState(() {
            _isCallInProgress = false;
            _currentCallingContact = null;
          });
          return;
        }

        if (callType == 'manual') {
          await _handleManualCall(contact, callerId);
          return;
        }

        // Use Click2Call IVR as the default IVR option
        if (callType == 'click2call' || callType == 'ivr') {
          await _handleClick2CallIVR(contact, callerId);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating call: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingContact = null;
        });
      }
    }
  }

  Future<void> _handleClick2CallIVR(DriverContact contact, int callerId) async {
    try {
      // Clean phone number
      final cleanDriverMobile = contact.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      debugPrint(
        '📞 Click2Call IVR - Driver: ${contact.name}, Mobile: $cleanDriverMobile',
      );

      if (!mounted) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating Click2Call IVR...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Initiate Click2Call IVR
      final result = await SmartCallingService.instance.initiateClick2CallIVR(
        driverMobile: cleanDriverMobile,
        callerId: callerId,
        driverId: contact.id,
      );

      debugPrint('🔔 Click2Call Result: $result');

      if (mounted) {
        if (result['success'] == true) {
          final referenceId = result['data']?['reference_id'];

          debugPrint('✅ Click2Call IVR initiated! Ref: $referenceId');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ IVR call initiated! Both phones will ring.\n'
                'Complete the call and submit feedback.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Show modern IVR waiting overlay
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: contact.name,
                  referenceId: referenceId,
                  onCallEnded: () {
                    Navigator.of(context).pop();
                    _showFeedbackModal(
                      contact,
                      referenceId: referenceId,
                      callDuration: 0,
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          // Show error
          final errorMsg = result['error'] ?? 'Unknown error';
          debugPrint('❌ Click2Call failed: $errorMsg');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate IVR call: $errorMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Click2Call error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingContact = null;
        });
      }
    }
  }

  Future<void> _handleManualCall(DriverContact contact, int callerId) async {
    try {
      // Clean phone number
      final cleanDriverMobile = contact.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      debugPrint(
        '📱 Manual Call - Driver: ${contact.name}, Mobile: $cleanDriverMobile',
      );

      // Log manual call to database
      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanDriverMobile,
        callerId: callerId,
        driverId: contact.id,
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId = result['data']?['reference_id'];
          final driverMobileRaw = result['data']?['driver_mobile_raw'];

          debugPrint('✅ Manual call logged - Ref: $referenceId');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${contact.name}...'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );

          // Make direct call using flutter_phone_direct_caller
          // This will automatically return to app when call ends
          try {
            await FlutterPhoneDirectCaller.callNumber(driverMobileRaw);

            debugPrint('📞 Direct call initiated to $driverMobileRaw');

            // Show feedback modal immediately after call is initiated
            // The modal will appear when user returns to app after call ends
            if (mounted) {
              // Small delay to ensure call screen has appeared
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted) {
                _showFeedbackModal(
                  contact,
                  referenceId: referenceId,
                  callDuration: 0,
                );
              }
            }
          } catch (callError) {
            debugPrint('❌ Direct call error: $callError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to make call: $callError'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          debugPrint('❌ Manual call failed: $errorMsg');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to log call: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Manual call error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingContact = null;
        });
      }
    }
  }

  void _showFeedbackModal(
    DriverContact contact, {
    String? referenceId,
    int? callDuration,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Cannot dismiss by tapping outside
      enableDrag: false, // Cannot dismiss by dragging down
      builder: (context) => PopScope(
        canPop: false, // Cannot dismiss with back button
        child: CallFeedbackModal(
          contact: contact,
          referenceId: referenceId,
          callDuration: callDuration,
          onFeedbackSubmitted: (feedback) {
            _updateContactStatus(
              contact,
              feedback,
              referenceId: referenceId,
              callDuration: callDuration,
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _updateContactStatus(
    DriverContact contact,
    CallFeedback feedback, {
    String? referenceId,
    int? callDuration,
  }) async {
    String feedbackText = '';

    switch (feedback.status) {
      case CallStatus.connected:
        feedbackText = feedback.connectedFeedback?.displayName ?? 'Connected';
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

    try {
      bool success = false;

      // If we have a reference ID from IVR call, update via that
      if (referenceId != null) {
        success = await SmartCallingService.instance.updateCallFeedback(
          referenceId: referenceId,
          callStatus: feedback.status.toString().split('.').last,
          feedback: feedbackText,
          remarks: feedback.remarks,
          callDuration: callDuration,
        );
      } else {
        // Fallback to regular status update
        success = await SmartCallingService.instance.updateCallStatus(
          driverId: contact.id,
          status: feedback.status,
          feedback: feedbackText,
          remarks: feedback.remarks,
        );
      }

      if (success && mounted) {
        // Remove contact from list after call is completed
        setState(() {
          _allContacts.removeWhere((c) => c.id == contact.id);
          _filteredContacts.removeWhere((c) => c.id == contact.id);
        });

        // Show success feedback
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call completed for ${contact.name}'),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback for ${contact.name}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving feedback: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Navigate back to dashboard
        context.go('/dashboard');
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildContactsList(),
                ),
              ],
            ),
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
                  'Smart Calling',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_filteredContacts.length} contacts available',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_in_talk,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterContacts,
        decoration: InputDecoration(
          hintText: 'Search drivers or transporters...',
          hintStyle: AppTheme.bodyLarge.copyWith(
            color: AppTheme.gray.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.gray.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        style: AppTheme.bodyLarge.copyWith(color: AppTheme.black),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading contacts...',
            style: TextStyle(color: AppTheme.gray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_filteredContacts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppTheme.gray.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts found',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.gray),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search terms',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.gray.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pull down to refresh',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryBlue,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = _filteredContacts[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeOutCubic,
              child: DriverContactCard(
                contact: contact,
                onCallPressed: () => _startCall(contact),
                isCallInProgress:
                    _isCallInProgress &&
                    _currentCallingContact?.id == contact.id,
              ),
            );
          },
        ),
      ),
    );
  }
}
