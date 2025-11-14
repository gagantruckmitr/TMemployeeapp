import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/state_code_mapper.dart';

class DriverDetailModal extends StatelessWidget {
  final DriverContact contact;

  const DriverDetailModal({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with avatar and name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.accentPurple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    contact.name,
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Company
                  Text(
                    contact.company,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Details section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TM ID
                    _buildDetailRow(
                      icon: Icons.badge_outlined,
                      label: 'TM ID',
                      value: contact.tmid,
                      iconColor: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 16),

                    // State
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'State',
                      value: StateCodeMapper.getStateName(contact.tmid),
                      iconColor: Colors.orange,
                    ),
                    const SizedBox(height: 16),

                    // City
                    _buildDetailRow(
                      icon: Icons.location_city_outlined,
                      label: 'City',
                      value: contact.state,
                      iconColor: Colors.purple,
                    ),
                    const SizedBox(height: 16),

                    // Registration Date
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Registration Date',
                      value: _formatDate(contact.registrationDate),
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 16),

                    // Subscription Status
                    _buildDetailRow(
                      icon: Icons.verified_outlined,
                      label: 'Subscription',
                      value: _getSubscriptionText(),
                      iconColor: _getSubscriptionColor(),
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSubscriptionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSubscriptionText(),
                          style: TextStyle(
                            color: _getSubscriptionColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Status
                    _buildDetailRow(
                      icon: Icons.payment_outlined,
                      label: 'Payment',
                      value: _getPaymentStatus(),
                      iconColor: _getPaymentStatusColor(),
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPaymentStatus(),
                          style: TextStyle(
                            color: _getPaymentStatusColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    // Payment Date (if available)
                    if (contact.paymentInfo?.paymentDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.date_range_outlined,
                        label: 'Payment Date',
                        value: _formatDate(contact.paymentInfo!.paymentDate),
                        iconColor: Colors.indigo,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Widget? valueWidget,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              valueWidget ??
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.black,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _getSubscriptionText() {
    switch (contact.subscriptionStatus) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.pending:
        return 'Pending';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.inactive:
        return 'No Subscription';
    }
  }

  Color _getSubscriptionColor() {
    switch (contact.subscriptionStatus) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.pending:
        return Colors.orange;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.inactive:
        return Colors.grey;
    }
  }

  String _getPaymentStatus() {
    if (contact.paymentInfo == null) return 'Not Captured';

    final status = contact.paymentInfo!.paymentStatus.toString().toLowerCase();
    if (status.contains('captured') ||
        status.contains('success') ||
        status.contains('paid')) {
      return 'Payment Captured';
    }

    return 'Not Captured';
  }

  Color _getPaymentStatusColor() {
    if (contact.paymentInfo == null) return Colors.grey;

    final status = contact.paymentInfo!.paymentStatus.toString().toLowerCase();
    if (status.contains('captured') ||
        status.contains('success') ||
        status.contains('paid')) {
      return Colors.green;
    }

    return Colors.grey;
  }
}
