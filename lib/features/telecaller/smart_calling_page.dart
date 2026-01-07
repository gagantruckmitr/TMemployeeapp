import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/smart_calling_models.dart';
import '../../core/services/smart_calling_service.dart';
import '../../core/services/real_auth_service.dart';
import '../../core/services/call_hit_service.dart';
import '../../core/services/today_leads_service.dart';
import '../../core/services/call_feedback_guard_service.dart';
import 'widgets/driver_contact_card.dart';

import 'widgets/call_feedback_modal.dart';
import 'widgets/transporter_feedback_modal.dart';
import 'widgets/call_type_selection_dialog.dart';
import 'widgets/ivr_call_waiting_overlay.dart';

class SmartCallingPage extends StatefulWidget {
  final String? tcFor; // 'match-making' or null for regular calling

  const SmartCallingPage({super.key, this.tcFor});

  @override
  State<SmartCallingPage> createState() => _SmartCallingPageState();
}

class _SmartCallingPageState extends State<SmartCallingPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<DriverContact> _filteredDrivers = [];
  List<DriverContact> _allDrivers = [];
  List<TransporterContact> _filteredTransporters = [];
  List<TransporterContact> _allTransporters = [];
  bool _isLoading = true;
  bool _isCallInProgress = false;
  DriverContact? _currentCallingDriver;
  TransporterContact? _currentCallingTransporter;
  int _remainingFreshLeads = 0; // Track remaining uncalled leads

  // Toggle state: 0 = Driver, 1 = Transporter
  int _selectedTab = 0;

  // Scroll controller for hiding search bar
  final ScrollController _scrollController = ScrollController();
  bool _isSearchBarVisible = true;
  double _lastScrollOffset = 0;

  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _searchBarAnimationController;
  late Animation<double> _searchBarAnimation;

  @override
  void initState() {
    super.initState();
    print('🔵 [SmartCalling] initState - tcFor: ${widget.tcFor}');

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

    // Search bar animation controller
    _searchBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 1.0, // Start visible
    );
    _searchBarAnimation = CurvedAnimation(
      parent: _searchBarAnimationController,
      curve: Curves.easeInOut,
    );

    // Listen to scroll changes
    _scrollController.addListener(_onScroll);

    // Initialize pending feedback check for call button visibility
    CallFeedbackGuardService.instance.getPendingCalls();

    _loadData();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final scrollDelta = currentOffset - _lastScrollOffset;

    // Only respond to significant scroll changes
    if (scrollDelta.abs() > 5) {
      if (scrollDelta > 0 && _isSearchBarVisible && currentOffset > 50) {
        // Scrolling down - hide search bar
        setState(() => _isSearchBarVisible = false);
        _searchBarAnimationController.reverse();
      } else if (scrollDelta < 0 && !_isSearchBarVisible) {
        // Scrolling up - show search bar
        setState(() => _isSearchBarVisible = true);
        _searchBarAnimationController.forward();
      }
      _lastScrollOffset = currentOffset;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideAnimationController.dispose();
    _searchBarAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    print(
      '🔵 [SmartCalling] _loadData START - tcFor: ${widget.tcFor}, selectedTab: $_selectedTab, forceRefresh: $forceRefresh',
    );
    try {
      if (widget.tcFor == 'match-making') {
        print('🔵 [SmartCalling] Match-making mode detected');
        if (_selectedTab == 0) {
          // Load drivers from LIVE API (same as fresh_leads_screen)
          print('🔵 [SmartCalling] Loading drivers from live API...');
          final drivers = await _loadDriversFromLiveAPI(
            forceRefresh: forceRefresh,
          );
          print(
            '🔵 [SmartCalling] Loaded ${drivers.length} drivers from live API',
          );
          if (mounted) {
            setState(() {
              _allDrivers = drivers;
              _filteredDrivers = List.from(_allDrivers);
              _allTransporters = [];
              _filteredTransporters = [];
              _isLoading = false;
            });
            print(
              '🔵 [SmartCalling] State updated - drivers: ${_allDrivers.length}',
            );
          }
        } else {
          // Load only transporters from LIVE API (filtered by role)
          print('🔵 [SmartCalling] Loading transporters from live API...');
          final transporters = await _loadTransportersFromLiveAPI(
            forceRefresh: forceRefresh,
          );
          print(
            '🔵 [SmartCalling] Loaded ${transporters.length} transporters from live API',
          );
          if (mounted) {
            setState(() {
              _allTransporters = transporters;
              _filteredTransporters = List.from(_allTransporters);
              _allDrivers = [];
              _filteredDrivers = [];
              _isLoading = false;
            });
            print(
              '🔵 [SmartCalling] State updated - transporters: ${_allTransporters.length}',
            );
          }
        }
      } else {
        // Regular mode - load based on selected tab
        if (_selectedTab == 0) {
          // Load drivers from LIVE API (same as fresh_leads_screen)
          print('🔵 [SmartCalling] Loading drivers from live API...');
          final drivers = await _loadDriversFromLiveAPI();
          print(
            '🔵 [SmartCalling] Loaded ${drivers.length} drivers from live API',
          );
          if (mounted) {
            setState(() {
              _allDrivers = drivers;
              _filteredDrivers = List.from(_allDrivers);
              _isLoading = false;
            });
          }
        } else {
          // Load transporters from LIVE API (filtered by role)
          print('🔵 [SmartCalling] Loading transporters from live API...');
          final transporters = await _loadTransportersFromLiveAPI();
          print(
            '🔵 [SmartCalling] Loaded ${transporters.length} transporters from live API',
          );
          if (mounted) {
            setState(() {
              _allTransporters = transporters;
              _filteredTransporters = List.from(_allTransporters);
              _isLoading = false;
            });
          }
        }
      }

      if (mounted) {
        _slideAnimationController.forward();
        print('🔵 [SmartCalling] Animation started');
      }
    } catch (e) {
      print('❌ [SmartCalling] Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    print('🔵 [SmartCalling] _loadData END');
  }

  /// Load drivers from the LIVE API (https://truckmitr.com/api/telehead/today-leads)
  /// Same data source as fresh_leads_screen.dart
  /// Only returns UNCALLED leads (limited by remaining_fresh count from API)
  /// Also fetches from elechamps API for additional leads
  /// FILTERS BY ROLE: Only returns drivers with role == 'driver'
  Future<List<DriverContact>> _loadDriversFromLiveAPI({
    bool forceRefresh = false,
  }) async {
    List<DriverContact> drivers = [];
    List<DriverContact> elechampsDrivers = [];

    try {
      // Use TodayLeadsService to get leads from live API
      // The service already filters by user and limits to remaining_fresh count
      final leads = await TodayLeadsService.instance.getTodayLeads(
        forceRefresh: forceRefresh,
      );

      // CRITICAL FIX: Filter only drivers (role == 'driver')
      final driverLeads = leads.where((lead) => lead.role == 'driver').toList();

      // Get remaining fresh leads count from service (this is the accurate count from API)
      _remainingFreshLeads = driverLeads.length;
      print(
        '🔵 [SmartCalling] Remaining fresh DRIVER leads from API: $_remainingFreshLeads',
      );
      print(
        '🔵 [SmartCalling] Driver leads returned from service: ${driverLeads.length}',
      );

      // Convert TodayLead to DriverContact
      // Service already sorted by newest first and limited to remaining_fresh count
      drivers = driverLeads
          .map((lead) => _convertTodayLeadToDriverContact(lead))
          .toList();
      print(
        '🔵 [SmartCalling] Converted ${drivers.length} today driver leads to DriverContact',
      );
    } catch (e) {
      print('⚠️ [SmartCalling] Error loading today leads: $e');
      // Continue to try elechamps even if today's leads fail
    }

    // Get current user ID for elechamps API
    final currentUser = RealAuthService.instance.currentUser;

    if (currentUser != null) {
      try {
        // Fetch elechamps leads
        print(
          '🔵 [SmartCalling] Fetching elechamps DRIVER leads for admin: ${currentUser.id}',
        );
        final allElechampsLeads = await SmartCallingService.instance
            .getElechampsLeads(adminId: currentUser.id, limit: 50);

        // CRITICAL FIX: Filter only drivers (role == 'driver')
        elechampsDrivers = allElechampsLeads
            .where((lead) => lead.role == 'driver')
            .toList();
        print(
          '✅ [SmartCalling] Elechamps DRIVER leads fetched: ${elechampsDrivers.length}',
        );
      } catch (e) {
        print('❌ [SmartCalling] Failed to fetch elechamps leads: $e');
      }
    } else {
      print('⚠️ [SmartCalling] No current user, cannot fetch elechamps leads');
    }

    // Merge both lists, removing duplicates by ID
    final allDrivers = <String, DriverContact>{};

    // Add today's leads first
    for (final driver in drivers) {
      allDrivers[driver.id] = driver;
    }

    // Add elechamps leads (will not override existing)
    for (final driver in elechampsDrivers) {
      if (!allDrivers.containsKey(driver.id)) {
        allDrivers[driver.id] = driver;
      }
    }

    // CRITICAL: Filter out processed leads from the merged list
    // This ensures leads with submitted feedback don't appear again on refresh
    final mergedDrivers = allDrivers.values.where((driver) {
      final leadId = int.tryParse(driver.id);
      if (leadId != null &&
          TodayLeadsService.instance.isLeadProcessed(leadId)) {
        print(
          '🔵 [SmartCalling] Filtering out processed lead: ${driver.id} (${driver.name})',
        );
        return false;
      }
      return true;
    }).toList();

    // Update count to match actual displayed leads
    _remainingFreshLeads = mergedDrivers.length;

    print(
      '🔵 [SmartCalling] Final count: ${mergedDrivers.length} drivers (filtered ${TodayLeadsService.instance.processedLeadsCount} processed)',
    );

    // If no leads at all, show helpful message
    if (mergedDrivers.isEmpty) {
      print('⚠️ [SmartCalling] No leads available from any source');
    }

    return mergedDrivers;
  }

  /// Convert TodayLead to DriverContact for use with DriverContactCard
  DriverContact _convertTodayLeadToDriverContact(TodayLead lead) {
    // Convert UTC to IST (UTC+5:30)
    DateTime? registrationDate;
    if (lead.createdAt.isNotEmpty) {
      final utcDate = DateTime.tryParse(lead.createdAt);
      if (utcDate != null) {
        // Convert to IST by adding 5 hours and 30 minutes
        registrationDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      }
    }

    return DriverContact(
      id: lead.id.toString(),
      tmid: lead.uniqueId,
      name: lead.nameEng.isNotEmpty ? lead.nameEng : lead.name,
      company: lead.role == 'driver' ? 'Driver' : 'Transporter',
      phoneNumber: lead.mobile,
      state: lead.states ?? '0',
      subscriptionStatus: SubscriptionStatus.inactive,
      status: CallStatus.pending,
      role: lead.role,
      registrationDate: registrationDate,
      profileCompletion: ProfileCompletion(
        percentage: lead.driverCompletion,
        documentStatus: {},
      ),
      assignedTelecaller: lead.assignedAdmin?.name,
    );
  }

  /// Load transporters from the LIVE API
  /// FILTERS BY ROLE: Only returns transporters with role == 'transporter'
  Future<List<TransporterContact>> _loadTransportersFromLiveAPI({
    bool forceRefresh = false,
  }) async {
    List<TransporterContact> transporters = [];

    try {
      // Use TodayLeadsService to get leads from live API
      final leads = await TodayLeadsService.instance.getTodayLeads(
        forceRefresh: forceRefresh,
      );

      // CRITICAL FIX: Filter only transporters (role == 'transporter')
      final transporterLeads = leads
          .where((lead) => lead.role == 'transporter')
          .toList();

      print(
        '🔵 [SmartCalling] Remaining fresh TRANSPORTER leads from API: ${transporterLeads.length}',
      );

      // Convert TodayLead to TransporterContact
      // Also filter out any processed leads (double-check)
      transporters = transporterLeads
          .where((lead) => !TodayLeadsService.instance.isLeadProcessed(lead.id))
          .map((lead) {
            // Convert UTC to IST (UTC+5:30)
            DateTime? registrationDate;
            if (lead.createdAt.isNotEmpty) {
              final utcDate = DateTime.tryParse(lead.createdAt);
              if (utcDate != null) {
                registrationDate = utcDate.add(
                  const Duration(hours: 5, minutes: 30),
                );
              }
            }

            return TransporterContact(
              id: lead.id.toString(),
              tmid: lead.uniqueId,
              name: lead.nameEng.isNotEmpty ? lead.nameEng : lead.name,
              company: 'Transporter',
              phoneNumber: lead.mobile,
              state: lead.states ?? '0',
              subscriptionStatus: SubscriptionStatus.inactive,
              status: CallStatus.pending,
              registrationDate: registrationDate,
              profileCompletion: ProfileCompletion(
                percentage: lead.driverCompletion,
                documentStatus: {},
              ),
            );
          })
          .toList();

      print(
        '🔵 [SmartCalling] Converted ${transporters.length} today transporter leads (filtered ${TodayLeadsService.instance.processedLeadsCount} processed)',
      );
    } catch (e) {
      print('⚠️ [SmartCalling] Error loading today transporter leads: $e');
    }

    return transporters;
  }

  void _filterContacts(String query) {
    print('🔵 [SmartCalling] _filterContacts - query: "$query"');
    setState(() {
      if (query.isEmpty) {
        _filteredDrivers = List.from(_allDrivers);
        _filteredTransporters = List.from(_allTransporters);
        print(
          '🔵 [SmartCalling] Filter cleared - drivers: ${_filteredDrivers.length}, transporters: ${_filteredTransporters.length}',
        );
      } else {
        _filteredDrivers = _allDrivers
            .where(
              (contact) =>
                  contact.name.toLowerCase().contains(query.toLowerCase()) ||
                  contact.company.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        _filteredTransporters = _allTransporters
            .where(
              (contact) =>
                  contact.name.toLowerCase().contains(query.toLowerCase()) ||
                  contact.company.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        print(
          '🔵 [SmartCalling] Filtered - drivers: ${_filteredDrivers.length}, transporters: ${_filteredTransporters.length}',
        );
      }
    });
  }

  Future<void> _startCall(DriverContact contact) async {
    if (_isCallInProgress) return;

    // Check for pending feedback before allowing call
    final hasPending = await CallFeedbackGuardService.instance
        .hasLastCallPendingFeedback();
    if (hasPending && mounted) {
      CallFeedbackGuardService.showPendingFeedbackToast(context);
      return;
    }

    setState(() {
      _isCallInProgress = true;
      _currentCallingDriver = contact;
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
            _currentCallingDriver = null;
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
          builder: (context) =>
              CallTypeSelectionDialog(driverName: contact.name),
        );

        if (callType == null) {
          setState(() {
            _isCallInProgress = false;
            _currentCallingDriver = null;
          });
          return;
        }

        // Determine contact type based on role field
        final contactType = contact.role == 'transporter'
            ? 'transporter'
            : 'driver';

        // Log call hit immediately when call button is pressed
        print(
          '🔵 Smart Calling: About to log call hit for ${contact.name} (role: ${contact.role}, type: $contactType)',
        );
        final logResult = await CallHitService.instance.logCallHit(
          contactId: contact.id,
          contactName: contact.name,
          contactType: contactType,
          callType: callType,
          sourceScreen: 'smart_calling',
          phoneNumber: contact.phoneNumber,
        );
        print('🔵 Smart Calling: Log result: $logResult');

        if (callType == 'manual') {
          await _handleManualCall(contact, callerId, contactType: contactType);
          return;
        }

        // Use EasyGo IVR (recommended)
        if (callType == 'easygo_ivr') {
          await _handleEasyGoIVR(contact, callerId, contactType: contactType);
          return;
        }

        // Fallback to Click2Call IVR (deprecated)
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
          _currentCallingDriver = null;
        });
      }
    }
  }

  Future<void> _startTransporterCall(TransporterContact contact) async {
    if (_isCallInProgress) return;

    // Check for pending feedback before allowing call
    final hasPending = await CallFeedbackGuardService.instance
        .hasLastCallPendingFeedback();
    if (hasPending && mounted) {
      CallFeedbackGuardService.showPendingFeedbackToast(context);
      return;
    }

    setState(() {
      _isCallInProgress = true;
      _currentCallingTransporter = contact;
    });

    try {
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
            _currentCallingTransporter = null;
          });
        }
        return;
      }

      final callerId = int.tryParse(currentUser.id) ?? 1;
      debugPrint(
        '🔵 Starting transporter call - Caller ID: $callerId, Transporter: ${contact.name} (${contact.phoneNumber})',
      );

      if (mounted) {
        final callType = await showDialog<String>(
          context: context,
          builder: (context) =>
              CallTypeSelectionDialog(driverName: contact.name),
        );

        if (callType == null) {
          setState(() {
            _isCallInProgress = false;
            _currentCallingTransporter = null;
          });
          return;
        }

        // Log call hit
        print(
          '🔵 Smart Calling: About to log call hit for transporter ${contact.name}',
        );
        final logResult = await CallHitService.instance.logCallHit(
          contactId: contact.id,
          contactName: contact.name,
          contactType: 'transporter',
          callType: callType,
          sourceScreen: 'smart_calling',
          phoneNumber: contact.phoneNumber,
        );
        print('🔵 Smart Calling: Log result: $logResult');

        if (callType == 'manual') {
          await _handleManualTransporterCall(contact, callerId);
          return;
        }

        if (callType == 'easygo_ivr') {
          await _handleEasyGoTransporterIVR(contact, callerId);
          return;
        }

        if (callType == 'click2call' || callType == 'ivr') {
          await _handleClick2CallTransporterIVR(contact, callerId);
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
          _currentCallingTransporter = null;
        });
      }
    }
  }

  Future<void> _handleEasyGoIVR(
    DriverContact contact,
    int callerId, {
    String contactType = 'driver',
  }) async {
    try {
      // Clean phone number
      final cleanDriverMobile = contact.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      // Get telecaller phone
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final telecallerPhone = currentUser.mobile.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      // Determine process based on contact type
      final process = contactType == 'transporter'
          ? 'Transporter Onboarding'
          : 'Driver Onboarding';

      debugPrint(
        '📞 EasyGo IVR - Telecaller: $telecallerPhone, Contact: ${contact.name} ($contactType), Mobile: $cleanDriverMobile, Process: $process',
      );

      if (!mounted) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating EasyGo IVR call...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Initiate EasyGo IVR with correct process based on contact type
      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanDriverMobile,
        callerId: callerId.toString(),
        contactId: contact.id,
        tmid: contact.tmid,
        contactType: contactType,
        process: process, // Dynamic process based on contact type
        driverName: contact.name,
      );

      debugPrint('🔔 EasyGo IVR Result: $result');

      if (mounted) {
        if (result['success'] == true) {
          final referenceId =
              result['reference_id'] ??
              result['call_id']?.toString() ??
              result['data']?['call_id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();

          debugPrint('✅ EasyGo IVR initiated! Ref: $referenceId');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ EasyGo IVR call initiated! Both phones will ring.\n'
                'Answer either phone to connect.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          // Show IVR waiting overlay
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
          // Show error
          final errorMsg = result['error'] ?? 'Unknown error';
          debugPrint('❌ EasyGo IVR failed: $errorMsg');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initiate EasyGo IVR call: $errorMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ EasyGo IVR error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingDriver = null;
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
              builder: (overlayContext) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: contact.name,
                  referenceId: referenceId,
                  onCallEnded: () {
                    // NOTE: Do NOT pop here - the IVRCallWaitingOverlay button
                    // already pops itself before calling this callback

                    // Add a small delay to ensure the pop animation completes
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        _showFeedbackModal(
                          contact,
                          referenceId: referenceId,
                          callDuration: 0,
                        );
                      }
                    });
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingDriver = null;
        });
      }
    }
  }

  Future<void> _handleManualCall(
    DriverContact contact,
    int callerId, {
    String contactType = 'driver',
  }) async {
    try {
      // Clean phone number
      final cleanDriverMobile = contact.phoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      debugPrint(
        '📱 Manual Call - Contact: ${contact.name} ($contactType), Mobile: $cleanDriverMobile',
      );

      // Log manual call to database with correct contact type
      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanDriverMobile,
        callerId: callerId,
        driverId: contact.id,
        contactType: contactType,
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
          _currentCallingDriver = null;
        });
      }
    }
  }

  void _showFeedbackModal(
    DriverContact contact, {
    String? referenceId,
    int? callDuration,
    bool isLiveEasyGo = false,
  }) {
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
        showRecordingUpload: false, // Hide manual call upload in Smart Calling
        onFeedbackSubmitted: (feedback) async {
          debugPrint(
            '🔵 [SmartCalling] Driver feedback modal callback triggered',
          );

          try {
            await _updateContactStatus(
              contact,
              feedback,
              referenceId: referenceId,
              callDuration: callDuration,
              isLiveEasyGo: isLiveEasyGo,
            );
            debugPrint('🔵 [SmartCalling] Driver feedback update completed');
          } catch (e) {
            debugPrint(
              '❌ [SmartCalling] Exception during driver feedback update: $e',
            );
          } finally {
            // Use modalContext to only pop the modal, not the page
            debugPrint(
              '🔵 [SmartCalling] Closing driver feedback modal (guaranteed)',
            );
            if (modalContext.mounted) {
              Navigator.of(modalContext, rootNavigator: false).pop();
            }
          }
        },
      ),
    );
  }

  void _showTransporterFeedbackModal(
    TransporterContact contact, {
    String? referenceId,
    int? callDuration,
    bool isLiveEasyGo = false,
  }) {
    print(
      'DEBUG: _showTransporterFeedbackModal called. isLiveEasyGo: $isLiveEasyGo',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Allow user to dismiss if stuck
      enableDrag: true, // Allow drag to dismiss
      builder: (modalContext) => TransporterFeedbackModal(
        contact: contact,
        referenceId: referenceId,
        callDuration: callDuration,
        onFeedbackSubmitted: (feedback) async {
          debugPrint(
            '🔵 [SmartCalling] Transporter feedback modal callback triggered',
          );

          // CRITICAL: Guaranteed modal closure using try/finally
          try {
            await _updateTransporterStatus(
              contact,
              feedback,
              referenceId: referenceId,
              callDuration: callDuration,
              isLiveEasyGo: isLiveEasyGo,
            );

            debugPrint('🔵 [SmartCalling] Feedback update completed');
          } catch (e) {
            debugPrint('❌ [SmartCalling] Exception during feedback update: $e');
          } finally {
            // ALWAYS close the modal - use modalContext to only pop the modal, not the page
            debugPrint(
              '🔵 [SmartCalling] Closing transporter feedback modal (guaranteed)',
            );
            if (modalContext.mounted) {
              Navigator.of(modalContext, rootNavigator: false).pop();
            }
          }
        },
      ),
    );
  }

  // Map CallStatus enum to database format
  String _mapCallStatusToDb(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return 'connected';
      case CallStatus.callBack:
        return 'not_connected'; // Fixed: 'callback' is not in DB enum
      case CallStatus.callBackLater:
        return 'callback_later';
      case CallStatus.notReachable:
        return 'not_connected'; // Fixed: 'not_reachable' -> 'not_connected'
      case CallStatus.notInterested:
        return 'connected'; // Typically 'not interested' happens after 'connected'
      case CallStatus.invalid:
        return 'not_connected';
      case CallStatus.pending:
        return 'not_connected';
    }
  }

  Future<void> _updateContactStatus(
    DriverContact contact,
    CallFeedback feedback, {
    String? referenceId,
    int? callDuration,
    bool isLiveEasyGo = false,
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

      // New Live EasyGo IVR Feedback Flow
      if (isLiveEasyGo && referenceId != null) {
        debugPrint(
          '🔵 [SmartCalling] Updating EasyGo Live Feedback: ref=$referenceId, status=${feedback.status}',
        );

        final callId = int.tryParse(referenceId);
        if (callId != null) {
          // Map status to string expected by API
          String dbStatus = _mapCallStatusToDb(feedback.status);

          success = await SmartCallingService.instance.updateEasyGoCallFeedback(
            callId: callId,
            status: dbStatus,
            feedback: feedbackText,
            remarks: feedback.remarks,
            recordingFile: feedback.recordingFile?.path,
          );

          debugPrint(
            '🔵 [SmartCalling] EasyGo Live Feedback update result: ${success ? "SUCCESS" : "FAILED"}',
          );
        } else {
          debugPrint(
            '❌ [SmartCalling] Invalid call ID for EasyGo Update: $referenceId',
          );
        }
      }
      // Legacy IVR / Click2Call Flow
      else if (referenceId != null) {
        // Map CallStatus enum to database format
        String dbStatus = _mapCallStatusToDb(feedback.status);

        debugPrint(
          '🔵 [SmartCalling] Updating feedback IMMEDIATELY: ref=$referenceId, status=$dbStatus, feedback=$feedbackText',
        );

        // CRITICAL: Update feedback immediately and wait for confirmation
        success = await SmartCallingService.instance.updateCallFeedback(
          referenceId: referenceId,
          callStatus: dbStatus,
          feedback: feedbackText,
          remarks: feedback.remarks,
          callDuration: callDuration,
          driverName: contact.name,
        );

        debugPrint(
          '🔵 [SmartCalling] Feedback update result: ${success ? "SUCCESS" : "FAILED"}',
        );
      } else {
        // Fallback to regular status update
        debugPrint(
          '🔵 [SmartCalling] No reference ID, using fallback update for driver: ${contact.id}',
        );
        success = await SmartCallingService.instance.updateCallStatus(
          driverId: contact.id,
          status: feedback.status,
          feedback: feedbackText,
          remarks: feedback.remarks,
        );
      }

      if (success && mounted) {
        debugPrint('✅ [SmartCalling] Feedback saved successfully to database');

        // Clear pending feedback cache since feedback was submitted
        CallFeedbackGuardService.instance.clearCache();

        // CRITICAL: Mark lead as processed in TodayLeadsService
        // This ensures the lead won't appear again even after refresh
        final leadId = int.tryParse(contact.id);
        if (leadId != null) {
          TodayLeadsService.instance.removeLeadFromCache(leadId);
          debugPrint(
            '✅ [SmartCalling] Marked lead $leadId as processed in TodayLeadsService',
          );
        }

        // Remove contact from list after call is completed and decrement remaining count
        setState(() {
          _allDrivers.removeWhere((c) => c.id == contact.id);
          _filteredDrivers.removeWhere((c) => c.id == contact.id);
          if (_remainingFreshLeads > 0) {
            _remainingFreshLeads--;
          }
        });

        // Show success feedback with remaining count
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Feedback saved for ${contact.name} • Remaining: $_remainingFreshLeads',
            ),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        debugPrint('❌ [SmartCalling] Failed to save feedback');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save feedback for ${contact.name}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SmartCalling] Error saving feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving feedback: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateTransporterStatus(
    TransporterContact contact,
    CallFeedback feedback, {
    String? referenceId,
    int? callDuration,
    bool isLiveEasyGo = false,
  }) async {
    print(
      'DEBUG: _updateTransporterStatus called. isLiveEasyGo: $isLiveEasyGo, Ref: $referenceId',
    );
    String feedbackText = '';

    switch (feedback.status) {
      case CallStatus.connected:
        feedbackText =
            feedback.transporterConnectedFeedback?.displayName ?? 'Connected';
        break;
      case CallStatus.callBack:
        feedbackText = feedback.callBackReason?.displayName ?? 'Call Back';
        break;
      case CallStatus.callBackLater:
        feedbackText = feedback.callBackTime?.displayName ?? 'Call Back Later';
        break;
      default:
        feedbackText = 'Unknown';
        break;
    }

    try {
      bool success = false;

      if (isLiveEasyGo && referenceId != null) {
        debugPrint(
          '🔵 [SmartCalling] Updating EasyGo Live Transporter Feedback: ref=$referenceId, status=${feedback.status}',
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
        }
      } else if (referenceId != null) {
        String dbStatus = _mapCallStatusToDb(feedback.status);

        debugPrint(
          '🔵 [SmartCalling] Updating transporter feedback IMMEDIATELY: ref=$referenceId, status=$dbStatus, feedback=$feedbackText',
        );

        // CRITICAL: Update feedback immediately and wait for confirmation
        success = await SmartCallingService.instance.updateCallFeedback(
          referenceId: referenceId,
          callStatus: dbStatus,
          feedback: feedbackText,
          remarks: feedback.remarks,
          callDuration: callDuration,
          driverName: contact.name,
        );

        debugPrint(
          '🔵 [SmartCalling] Transporter feedback update result: ${success ? "SUCCESS" : "FAILED"}',
        );
      } else {
        debugPrint(
          '🔵 [SmartCalling] No reference ID, using fallback update for transporter: ${contact.id}',
        );
        success = await SmartCallingService.instance
            .updateTransporterCallStatus(
              transporterId: contact.id,
              status: feedback.status,
              feedback: feedbackText,
              remarks: feedback.remarks,
            );
      }

      if (success) {
        debugPrint('✅ [SmartCalling] Feedback updated successfully');

        // Clear pending feedback cache since feedback was submitted
        CallFeedbackGuardService.instance.clearCache();

        // CRITICAL: Mark lead as processed in TodayLeadsService
        // This ensures the lead won't appear again even after refresh
        final leadId = int.tryParse(contact.id);
        if (leadId != null) {
          TodayLeadsService.instance.removeLeadFromCache(leadId);
          debugPrint(
            '✅ [SmartCalling] Marked transporter $leadId as processed in TodayLeadsService',
          );
        }

        if (mounted) {
          // Then update UI state
          setState(() {
            _allTransporters.removeWhere((c) => c.id == contact.id);
            _filteredTransporters.removeWhere((c) => c.id == contact.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Feedback saved for ${contact.name}'),
              backgroundColor: AppTheme.primaryBlue,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        debugPrint('❌ [SmartCalling] Failed to save transporter feedback');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save feedback for ${contact.name}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SmartCalling] Error saving transporter feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving feedback: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Transporter call handlers
  Future<void> _handleEasyGoTransporterIVR(
    TransporterContact contact,
    int callerId,
  ) async {
    try {
      final cleanMobile = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final currentUser = RealAuthService.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final telecallerPhone = currentUser.mobile.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating EasyGo IVR call...'),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await SmartCallingService.instance.initiateEasyGoIVR(
        telecallerPhone: telecallerPhone,
        clientPhone: cleanMobile,
        callerId: callerId.toString(),
        contactId: contact.id,
        tmid: contact.tmid,
        contactType: 'transporter',
        process: 'Transporter Onboarding', // Process type for transporter calls
        driverName: contact.name,
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId =
              result['reference_id'] ??
              result['call_id']?.toString() ??
              result['data']?['call_id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ EasyGo IVR call initiated!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

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
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        _showTransporterFeedbackModal(
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
          final errorMsg = result['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingTransporter = null;
        });
      }
    }
  }

  Future<void> _handleClick2CallTransporterIVR(
    TransporterContact contact,
    int callerId,
  ) async {
    try {
      final cleanMobile = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📞 Initiating Click2Call IVR...'),
          duration: Duration(seconds: 2),
        ),
      );

      final result = await SmartCallingService.instance.initiateClick2CallIVR(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: contact.id,
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId = result['data']?['reference_id'];

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ IVR call initiated!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => PopScope(
                canPop: false,
                child: IVRCallWaitingOverlay(
                  driverName: contact.name,
                  referenceId: referenceId,
                  onCallEnded: () {
                    // NOTE: Do NOT pop here - the IVRCallWaitingOverlay button
                    // already pops itself before calling this callback

                    // Add a small delay to ensure the pop animation completes
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        _showTransporterFeedbackModal(
                          contact,
                          referenceId: referenceId,
                          callDuration: 0,
                        );
                      }
                    });
                  },
                ),
              ),
            ),
          );
        } else {
          final errorMsg = result['error'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingTransporter = null;
        });
      }
    }
  }

  Future<void> _handleManualTransporterCall(
    TransporterContact contact,
    int callerId,
  ) async {
    try {
      final cleanMobile = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      final result = await SmartCallingService.instance.initiateManualCall(
        driverMobile: cleanMobile,
        callerId: callerId,
        driverId: contact.id,
        contactType: 'transporter',
      );

      if (mounted) {
        if (result['success'] == true) {
          final referenceId = result['data']?['reference_id'];
          final mobileRaw = result['data']?['driver_mobile_raw'];

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Calling ${contact.name}...'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );

          try {
            await FlutterPhoneDirectCaller.callNumber(mobileRaw);

            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              _showTransporterFeedbackModal(
                contact,
                referenceId: referenceId,
                callDuration: 0,
              );
            }
          } catch (callError) {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: $errorMsg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCallInProgress = false;
          _currentCallingTransporter = null;
        });
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildToggleSection(),
              // Animated search bar that hides on scroll
              SizeTransition(
                sizeFactor: _searchBarAnimation,
                axisAlignment: -1.0,
                child: _buildSearchBar(),
              ),
              Expanded(
                child: _isLoading ? _buildLoadingState() : _buildContactsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    int contactCount;
    String contactType;

    if (_selectedTab == 0) {
      // Use remaining fresh leads count for drivers (from API)
      contactCount = _remainingFreshLeads;
      contactType = 'drivers';
    } else {
      contactCount = _filteredTransporters.length;
      contactType = 'transporters';
    }

    final title = widget.tcFor == 'match-making'
        ? 'Match Making'
        : 'Smart Calling';
    print(
      '🔵 [SmartCalling] _buildHeader - title: $title, count: $contactCount $contactType',
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Apple-style back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$contactCount $contactType available',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Apple-style Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34C759), Color(0xFF30D158)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C759).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_in_talk, color: Colors.white, size: 14),
                SizedBox(width: 5),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7), // iOS system gray 6
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('🔵 [SmartCalling] Toggle tapped - Drivers');
                if (_selectedTab != 0) {
                  print('🔵 [SmartCalling] Switching to Drivers tab');
                  setState(() {
                    _selectedTab = 0;
                    _isLoading = true;
                    if (widget.tcFor == 'match-making') {
                      _searchController.clear();
                    }
                  });
                  HapticFeedback.selectionClick();
                  _loadData();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      color: _selectedTab == 0
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF8E8E93),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Drivers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedTab == 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _selectedTab == 0
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                print('🔵 [SmartCalling] Toggle tapped - Transporters');
                if (_selectedTab != 1) {
                  print('🔵 [SmartCalling] Switching to Transporters tab');
                  setState(() {
                    _selectedTab = 1;
                    _isLoading = true;
                    if (widget.tcFor == 'match-making') {
                      _searchController.clear();
                    }
                  });
                  HapticFeedback.selectionClick();
                  _loadData();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_rounded,
                      color: _selectedTab == 1
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF8E8E93),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Transporters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedTab == 1
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _selectedTab == 1
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7), // iOS system gray 6
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterContacts,
        style: const TextStyle(fontSize: 17, color: Color(0xFF1C1C1E)),
        decoration: InputDecoration(
          hintText: 'Search drivers or transporters...',
          hintStyle: TextStyle(fontSize: 17, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading contacts...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    List<dynamic> contacts;
    String contactType;

    if (_selectedTab == 0) {
      contacts = _filteredDrivers;
      contactType = 'drivers';
    } else {
      contacts = _filteredTransporters;
      contactType = 'transporters';
    }

    print(
      '🔵 [SmartCalling] _buildContactsList - showing: $contactType, count: ${contacts.length}',
    );

    if (contacts.isEmpty) {
      print('🔵 [SmartCalling] No contacts to display');

      return RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        color: const Color(0xFF007AFF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No $contactType found',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search terms',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
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
      onRefresh: () => _loadData(forceRefresh: true),
      color: const Color(0xFF007AFF),
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            // Safety check to prevent RangeError
            if (index < 0 || index >= contacts.length) {
              print(
                '⚠️ [SmartCalling] Index out of bounds: $index >= ${contacts.length}',
              );
              return const SizedBox.shrink();
            }

            try {
              if (_selectedTab == 0) {
                // Drivers tab - ensure we're accessing the correct list
                if (index >= _filteredDrivers.length) {
                  print(
                    '⚠️ [SmartCalling] Driver index out of bounds: $index >= ${_filteredDrivers.length}',
                  );
                  return const SizedBox.shrink();
                }
                final contact = _filteredDrivers[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  child: DriverContactCard(
                    contact: contact,
                    showAssignedTo: false,
                    onCallPressed: () => _startCall(contact),
                    isCallInProgress:
                        _isCallInProgress &&
                        _currentCallingDriver?.id == contact.id,
                  ),
                );
              } else if (_selectedTab == 1) {
                // Transporters tab - ensure we're accessing the correct list
                if (index >= _filteredTransporters.length) {
                  print(
                    '⚠️ [SmartCalling] Transporter index out of bounds: $index >= ${_filteredTransporters.length}',
                  );
                  return const SizedBox.shrink();
                }
                final contact = _filteredTransporters[index];
                // Convert TransporterContact to DriverContact
                final driverContact = DriverContact(
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
                  profilePicture: contact.profilePicture,
                  role: 'transporter',
                  // Initialize default values for fields not in TransporterContact
                  assignedTelecaller: null,
                  callHistory: [],
                  trainingInfo: null,
                  postedJobs: [],
                  matchMakingHistory: [],
                  appliedJobs: [],
                  fleetSize: null,
                );

                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  child: DriverContactCard(
                    contact: driverContact,
                    showAssignedTo: false,
                    onCallPressed: () => _startTransporterCall(contact),
                    isCallInProgress:
                        _isCallInProgress &&
                        _currentCallingTransporter?.id == contact.id,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            } catch (e) {
              print(
                '❌ [SmartCalling] Error building contact card at index $index: $e',
              );
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
