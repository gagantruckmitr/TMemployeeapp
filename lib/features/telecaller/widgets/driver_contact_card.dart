import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/utils/state_code_mapper.dart';
import 'profile_completion_avatar.dart';
import '../screens/profile_completion_details_page.dart';

class DriverContactCard extends StatefulWidget {
  final DriverContact contact;
  final VoidCallback onCallPressed;
  final bool isCallInProgress;

  const DriverContactCard({
    super.key,
    required this.contact,
    required this.onCallPressed,
    this.isCallInProgress = false,
  });

  @override
  State<DriverContactCard> createState() => _DriverContactCardState();
}

class _DriverContactCardState extends State<DriverContactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  String _formatRegistrationDate() {
    // Use actual registration date from database
    final date = widget.contact.registrationDate ?? DateTime.now();
    return DateFormat('dd MMM yyyy').format(date);
  }

  bool _hasSubscription() {
    return widget.contact.subscriptionStatus == SubscriptionStatus.active ||
           widget.contact.paymentInfo?.paymentStatus == PaymentStatus.success;
  }

  String _getSubscriptionText() {
    final paymentInfo = widget.contact.paymentInfo;
    
    if (paymentInfo != null && paymentInfo.subscriptionType != null) {
      return paymentInfo.subscriptionType!;
    }
    
    if (_hasSubscription()) {
      return 'Active';
    }
    
    return 'No Subscription';
  }

  Color _getSubscriptionColor() {
    final paymentInfo = widget.contact.paymentInfo;
    
    if (paymentInfo?.paymentStatus == PaymentStatus.success) {
      return const Color(0xFF4CAF50); // Green
    } else if (paymentInfo?.paymentStatus == PaymentStatus.pending) {
      return const Color(0xFFFFC107); // Orange
    } else if (paymentInfo?.paymentStatus == PaymentStatus.failed) {
      return const Color(0xFFF44336); // Red
    }
    
    return Colors.grey.shade600; // Default
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
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
                      // Avatar with profile completion - Tap to view details
                      ProfileCompletionAvatar(
                        name: widget.contact.name,
                        completionPercentage: widget.contact.profileCompletion?.percentage ?? 0,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileCompletionDetailsPage(
                                contact: widget.contact,
                              ),
                            ),
                          );
                        },
                        size: 54,
                      ),
                      const SizedBox(width: 14),

                      // Name
                      Expanded(
                        child: Text(
                          widget.contact.name,
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

                      const SizedBox(width: 12),

                      // Call Button
                      GestureDetector(
                        onTap: widget.isCallInProgress
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                widget.onCallPressed();
                              },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.isCallInProgress
                                ? Colors.grey.shade300
                                : const Color(0xFF2196F3),
                            shape: BoxShape.circle,
                            boxShadow: widget.isCallInProgress
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: widget.isCallInProgress
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : const Icon(
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
                          _formatRegistrationDate(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.location_on_outlined,
                          'State',
                          StateCodeMapper.getStateName(widget.contact.tmid),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildSubscriptionItem(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.badge_outlined,
                          'TMID',
                          widget.contact.tmid,
                        ),
                      ),
                    ],
                  ),
                  
                  // Show feedback if available
                  if (widget.contact.lastFeedback != null && 
                      widget.contact.lastFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildFeedbackSection(),
                  ],
                  
                  // Show remarks if available
                  if (widget.contact.remarks != null && 
                      widget.contact.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildRemarksSection(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem() {
    final subscriptionText = _getSubscriptionText();
    final subscriptionColor = _getSubscriptionColor();
    final hasSubscription = _hasSubscription();

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

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Feedback',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.contact.lastFeedback!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.note_outlined,
            size: 16,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remarks',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.contact.remarks!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
