import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/services/subscription_service.dart';
import '../../../models/subscription_model.dart';
import '../../../widgets/error_handler.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  List<TelecallerSubscription> _subscriptions = [];
  bool _isLoading = true;
  String _selectedPeriod = 'today';
  final Set<int> _expandedCards = {};

  final List<Map<String, String>> _periodFilters = [
    {'key': 'today', 'label': 'Today'},
    {'key': 'yesterday', 'label': 'Yesterday'},
    {'key': 'week', 'label': 'This Week'},
    {'key': 'month', 'label': 'This Month'},
    {'key': 'all', 'label': 'All'},
  ];

  // Responsive helpers
  double _getCardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 10;
    if (width < 400) return 12;
    return 14;
  }

  double _getAvatarSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 36;
    if (width < 400) return 40;
    return 44;
  }

  double _getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.85;
    if (width < 400) return 0.92;
    return 1.0;
  }

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      final subscriptions = await SubscriptionService.instance.getSubscriptions(
        period: _selectedPeriod,
      );
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showError(context, e, onRetry: _loadSubscriptions);
      }
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod != period) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedPeriod = period;
      });
      _loadSubscriptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS system background
      body: Column(
        children: [
          _buildAppleHeader(),
          _buildFilterChips(),
          _buildStatsCard(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF007AFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading subscriptions...',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _subscriptions.isEmpty
                ? _buildEmptyState()
                : _buildSubscriptionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleHeader() {
    final fontScale = _getFontScale(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * fontScale,
            vertical: 10 * fontScale,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(6 * fontScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16 * fontScale,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
              SizedBox(width: 12 * fontScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My Subscriptions',
                      style: TextStyle(
                        fontSize: 17 * fontScale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_subscriptions.length} subscriptions',
                      style: TextStyle(
                        fontSize: 11 * fontScale,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _loadSubscriptions();
                },
                child: Container(
                  padding: EdgeInsets.all(8 * fontScale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18 * fontScale,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final fontScale = _getFontScale(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8 * fontScale),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _periodFilters.map((filter) {
            final isSelected = _selectedPeriod == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _onPeriodChanged(filter['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * fontScale,
                    vertical: 7 * fontScale,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF007AFF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF007AFF,
                              ).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    filter['label']!,
                    style: TextStyle(
                      fontSize: 12 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalRevenue = _subscriptions.fold<double>(
      0,
      (sum, sub) => sum + sub.amount,
    );
    final fontScale = _getFontScale(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.all(14 * fontScale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30D158)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34C759).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * fontScale),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 14 * fontScale,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Subscriptions',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12 * fontScale,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * fontScale),
                Text(
                  '${_subscriptions.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28 * fontScale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 10 * fontScale),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6 * fontScale),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.currency_rupee_rounded,
                        color: Colors.white,
                        size: 14 * fontScale,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Revenue',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12 * fontScale,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * fontScale),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * fontScale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      color: const Color(0xFF007AFF),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = _subscriptions[index];
          return _buildSubscriptionCard(subscription, index);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(
    TelecallerSubscription subscription,
    int index,
  ) {
    final isPaid =
        subscription.paymentStatus.toLowerCase() == 'paid' ||
        subscription.paymentStatus.toLowerCase() == 'success';
    final isExpanded = _expandedCards.contains(index);
    final cardPadding = _getCardPadding(context);
    final avatarSize = _getAvatarSize(context);
    final fontScale = _getFontScale(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isExpanded) {
            _expandedCards.remove(index);
          } else {
            _expandedCards.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isExpanded ? 0.06 : 0.03),
              blurRadius: isExpanded ? 12 : 6,
              offset: Offset(0, isExpanded ? 4 : 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Card Content - Slim Design
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  children: [
                    // Compact Avatar
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF30D158)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: avatarSize * 0.5,
                      ),
                    ),
                    SizedBox(width: 10 * fontScale),

                    // Info Section - Compact
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            subscription.driverName,
                            style: TextStyle(
                              fontSize: 14 * fontScale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1C1E),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3 * fontScale),
                          // Tags Row - Wrapped for small screens
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _buildCompactTag(
                                subscription.driverTmid,
                                const Color(0xFF007AFF),
                                fontScale,
                              ),
                              _buildStatusTag(
                                isPaid,
                                subscription.paymentStatus,
                                fontScale,
                              ),
                            ],
                          ),
                          SizedBox(height: 3 * fontScale),
                          Text(
                            DateFormat(
                              'dd MMM, hh:mm a',
                            ).format(subscription.paymentStartTime),
                            style: TextStyle(
                              fontSize: 10 * fontScale,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 6 * fontScale),

                    // Amount & Arrow - Compact
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * fontScale,
                            vertical: 5 * fontScale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF34C759,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹${NumberFormat('#,##,###').format(subscription.amount)}',
                            style: TextStyle(
                              fontSize: 13 * fontScale,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34C759),
                            ),
                          ),
                        ),
                        SizedBox(height: 4 * fontScale),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18 * fontScale,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expanded Details
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedDetails(subscription),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTag(String text, Color color, double fontScale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * fontScale,
        vertical: 2 * fontScale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * fontScale,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusTag(bool isPaid, String status, double fontScale) {
    final color = isPaid ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * fontScale,
        vertical: 2 * fontScale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 10 * fontScale,
            color: color,
          ),
          SizedBox(width: 2 * fontScale),
          Text(
            isPaid ? 'Paid' : status,
            style: TextStyle(
              fontSize: 9 * fontScale,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(TelecallerSubscription subscription) {
    final fontScale = _getFontScale(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        12 * fontScale,
        0,
        12 * fontScale,
        12 * fontScale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.only(bottom: 10 * fontScale),
            decoration: BoxDecoration(color: Colors.grey.shade200),
          ),

          // Subscription Period - Responsive Layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 280) {
                // Stack vertically on very small screens
                return Column(
                  children: [
                    _buildCompactDetailItem(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Start',
                      value: DateFormat(
                        'dd MMM yy',
                      ).format(subscription.startAt),
                      color: const Color(0xFF007AFF),
                      fontScale: fontScale,
                    ),
                    SizedBox(height: 8 * fontScale),
                    _buildCompactDetailItem(
                      icon: Icons.stop_circle_outlined,
                      label: 'End',
                      value: DateFormat('dd MMM yy').format(subscription.endAt),
                      color: const Color(0xFFFF3B30),
                      fontScale: fontScale,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailItem(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Start',
                      value: DateFormat(
                        'dd MMM yy',
                      ).format(subscription.startAt),
                      color: const Color(0xFF007AFF),
                      fontScale: fontScale,
                    ),
                  ),
                  SizedBox(width: 8 * fontScale),
                  Expanded(
                    child: _buildCompactDetailItem(
                      icon: Icons.stop_circle_outlined,
                      label: 'End',
                      value: DateFormat('dd MMM yy').format(subscription.endAt),
                      color: const Color(0xFFFF3B30),
                      fontScale: fontScale,
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 8 * fontScale),

          // Payment Date & Time
          _buildCompactDetailItem(
            icon: Icons.schedule_rounded,
            label: 'Payment',
            value: DateFormat(
              'dd MMM yy, hh:mm a',
            ).format(subscription.paymentStartTime),
            color: const Color(0xFF5856D6),
            fontScale: fontScale,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double fontScale,
  }) {
    return Container(
      padding: EdgeInsets.all(10 * fontScale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5 * fontScale),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14 * fontScale, color: color),
          ),
          SizedBox(width: 8 * fontScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9 * fontScale,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1 * fontScale),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11 * fontScale,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final fontScale = _getFontScale(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(18 * fontScale),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 40 * fontScale,
                color: const Color(0xFF34C759),
              ),
            ),
            SizedBox(height: 16 * fontScale),
            Text(
              'No Subscriptions Yet',
              style: TextStyle(
                fontSize: 17 * fontScale,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 6 * fontScale),
            Text(
              'Keep calling drivers to get subscriptions!',
              style: TextStyle(
                fontSize: 13 * fontScale,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18 * fontScale),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _loadSubscriptions();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * fontScale,
                  vertical: 10 * fontScale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 16 * fontScale,
                    ),
                    SizedBox(width: 6 * fontScale),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
