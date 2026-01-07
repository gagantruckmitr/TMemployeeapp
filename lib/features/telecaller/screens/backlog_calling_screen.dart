import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../widgets/driver_contact_card.dart';

class BacklogCallingScreen extends StatefulWidget {
  const BacklogCallingScreen({super.key});

  @override
  State<BacklogCallingScreen> createState() => _BacklogCallingScreenState();
}

class _BacklogCallingScreenState extends State<BacklogCallingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<DriverContact> _filteredDrivers = [];
  List<DriverContact> _allDrivers = [];
  bool _isLoading = false;

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

    _loadDummyData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  void _loadDummyData() {
    // Create dummy driver contacts for backlog calling
    _allDrivers = [
      DriverContact(
        id: '1001',
        tmid: 'TM001',
        name: 'Rajesh Kumar',
        company: 'Kumar Transport',
        phoneNumber: '+91 98765 43210',
        state: 'Maharashtra',
        subscriptionStatus: SubscriptionStatus.active,
        status: CallStatus.callBack,
        lastFeedback: 'Call Back Later',
        lastCallTime: DateTime.now().subtract(const Duration(hours: 2)),
        remarks: 'Interested in premium subscription',
        registrationDate: DateTime.now().subtract(const Duration(days: 15)),
        profileCompletion: ProfileCompletion(
          percentage: 75,
          documentStatus: {'vehicle_documents': false},
        ),
        role: 'driver',
        callHistory: [
          CallHistoryEntry(
            id: '1',
            callerId: '1',
            callTime: DateTime.now().subtract(const Duration(hours: 2)),
            callStatus: 'callback',
            feedback: 'Call Back Later',
            telecallerName: 'Ankit',
            callType: 'welcome_call',
          ),
        ],
      ),
      DriverContact(
        id: '1002',
        tmid: 'TM002',
        name: 'Suresh Patel',
        company: 'Patel Logistics',
        phoneNumber: '+91 98765 43211',
        state: 'Gujarat',
        subscriptionStatus: SubscriptionStatus.pending,
        status: CallStatus.notReachable,
        lastFeedback: 'Not Reachable',
        lastCallTime: DateTime.now().subtract(const Duration(hours: 5)),
        remarks: 'Try calling after 6 PM',
        registrationDate: DateTime.now().subtract(const Duration(days: 10)),
        profileCompletion: ProfileCompletion(
          percentage: 60,
          documentStatus: {'vehicle_documents': false, 'license': false},
        ),
        role: 'driver',
        callHistory: [
          CallHistoryEntry(
            id: '2',
            callerId: '1',
            callTime: DateTime.now().subtract(const Duration(hours: 5)),
            callStatus: 'not_reachable',
            feedback: 'Not Reachable',
            telecallerName: 'Priya',
            callType: 'welcome_call',
          ),
        ],
      ),
      DriverContact(
        id: '1003',
        tmid: 'TM003',
        name: 'Amit Singh',
        company: 'Singh Carriers',
        phoneNumber: '+91 98765 43212',
        state: 'Punjab',
        subscriptionStatus: SubscriptionStatus.active,
        status: CallStatus.callBack,
        lastFeedback: 'Busy, Call Back',
        lastCallTime: DateTime.now().subtract(const Duration(hours: 1)),
        remarks: 'Wants to discuss pricing',
        registrationDate: DateTime.now().subtract(const Duration(days: 20)),
        profileCompletion: ProfileCompletion(
          percentage: 85,
          documentStatus: {},
        ),
        role: 'driver',
        callHistory: [
          CallHistoryEntry(
            id: '3',
            callerId: '1',
            callTime: DateTime.now().subtract(const Duration(hours: 1)),
            callStatus: 'callback',
            feedback: 'Busy, Call Back',
            telecallerName: 'Rahul',
            callType: 'welcome_call',
          ),
          CallHistoryEntry(
            id: '4',
            callerId: '1',
            callTime: DateTime.now().subtract(const Duration(days: 1)),
            callStatus: 'connected',
            feedback: 'Interested',
            telecallerName: 'Rahul',
            callType: 'welcome_call',
          ),
        ],
      ),
      DriverContact(
        id: '1004',
        tmid: 'TM004',
        name: 'Vijay Sharma',
        company: 'Sharma Transport Co.',
        phoneNumber: '+91 98765 43213',
        state: 'Rajasthan',
        subscriptionStatus: SubscriptionStatus.pending,
        status: CallStatus.callBack,
        lastFeedback: 'Call Back Tomorrow',
        lastCallTime: DateTime.now().subtract(const Duration(hours: 24)),
        remarks: 'Needs time to think',
        registrationDate: DateTime.now().subtract(const Duration(days: 5)),
        profileCompletion: ProfileCompletion(
          percentage: 50,
          documentStatus: {
            'vehicle_documents': false,
            'license': false,
            'bank_details': false
          },
        ),
        role: 'driver',
        callHistory: [
          CallHistoryEntry(
            id: '5',
            callerId: '1',
            callTime: DateTime.now().subtract(const Duration(hours: 24)),
            callStatus: 'callback',
            feedback: 'Call Back Tomorrow',
            telecallerName: 'Ankit',
            callType: 'welcome_call',
          ),
        ],
      ),
      DriverContact(
        id: '1005',
        tmid: 'TM005',
        name: 'Deepak Verma',
        company: 'Verma Roadways',
        phoneNumber: '+91 98765 43214',
        state: 'Uttar Pradesh',
        subscriptionStatus: SubscriptionStatus.active,
        status: CallStatus.notReachable,
        lastFeedback: 'Switched Off',
        lastCallTime: DateTime.now().subtract(const Duration(hours: 3)),
        remarks: 'Phone switched off',
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
        profileCompletion: ProfileCompletion(
          percentage: 90,
          documentStatus: {},
        ),
        role: 'driver',
        callHistory: [
          CallHistoryEntry(
            id: '6',
            callerId: '1',
            callTime: DateTime.now().subtract(const Duration(hours: 3)),
            callStatus: 'not_reachable',
            feedback: 'Switched Off',
            telecallerName: 'Priya',
            callType: 'welcome_call',
          ),
        ],
      ),
    ];

    _filteredDrivers = List.from(_allDrivers);
    _slideAnimationController.forward();
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrivers = List.from(_allDrivers);
      } else {
        _filteredDrivers = _allDrivers
            .where(
              (contact) =>
                  contact.name.toLowerCase().contains(query.toLowerCase()) ||
                  contact.company.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _handleCallPressed(DriverContact contact) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${contact.name}...'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
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
                  'Backlog Calling',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_filteredDrivers.length} callbacks pending',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Backlog',
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
          hintText: 'Search backlog contacts...',
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
          const SizedBox(height: 16),
          Text(
            'Loading backlog contacts...',
            style: TextStyle(color: AppTheme.gray, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_filteredDrivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.gray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No backlog contacts',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.gray),
            ),
            const SizedBox(height: 8),
            Text(
              'All callbacks have been completed!',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.gray.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredDrivers.length,
        itemBuilder: (context, index) {
          final contact = _filteredDrivers[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutCubic,
            child: DriverContactCard(
              contact: contact,
              showAssignedTo: false,
              onCallPressed: () => _handleCallPressed(contact),
              isCallInProgress: false,
            ),
          );
        },
      ),
    );
  }
}
