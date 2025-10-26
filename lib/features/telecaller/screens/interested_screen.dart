import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';
import '../../../core/services/smart_calling_service.dart';
import '../widgets/driver_contact_card.dart';
import '../widgets/call_feedback_modal.dart';

class InterestedScreen extends StatefulWidget {
  const InterestedScreen({super.key});

  @override
  State<InterestedScreen> createState() => _InterestedScreenState();
}

class _InterestedScreenState extends State<InterestedScreen>
    with AutomaticKeepAliveClientMixin {
  List<DriverContact>? _interestedContacts;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInterestedContactsAsync();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInterestedContactsAsync() async {
    try {
      final contacts = await SmartCallingService.instance.getDriversByCategory(NavigationSection.interested);
      
      if (mounted) {
        setState(() {
          _interestedContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _interestedContacts = [];
          _isLoading = false;
        });
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
      builder: (context) => CallFeedbackModal(
        contact: contact,
        onFeedbackSubmitted: (feedback) {
          _handleFeedbackSubmitted(contact, feedback);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleFeedbackSubmitted(DriverContact contact, CallFeedback feedback) {
    if (_interestedContacts == null) return;
    
    setState(() {
      final index = _interestedContacts!.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _interestedContacts![index] = contact.copyWith(
          status: feedback.status,
          lastFeedback: _getFeedbackText(feedback),
          lastCallTime: DateTime.now(),
        );
        
        // Remove from interested if status changed
        if (feedback.status != CallStatus.connected ||
            !_isInterestedFeedback(feedback)) {
          _interestedContacts!.removeAt(index);
        }
      }
    });
    
    HapticFeedback.lightImpact();
  }

  bool _isInterestedFeedback(CallFeedback feedback) {
    if (feedback.connectedFeedback == null) return false;
    
    final feedbackText = feedback.connectedFeedback!.displayName;
    return feedbackText.contains('Agree') ||
           feedbackText.contains('Demo') ||
           feedbackText.contains('Subscribe');
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
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _InterestedHeader(contactCount: _interestedContacts?.length ?? 0),
          Expanded(
            child: _isLoading
                ? const _LoadingWidget()
                : (_interestedContacts?.isEmpty ?? true)
                    ? const _EmptyStateWidget()
                    : _ContactsList(
                        contacts: _interestedContacts!,
                        scrollController: _scrollController,
                        onCallPressed: _onCallPressed,
                      ),
          ),
        ],
      ),
    );
  }

}

// Optimized separate widgets to prevent unnecessary rebuilds
class _InterestedHeader extends StatelessWidget {
  final int contactCount;

  const _InterestedHeader({required this.contactCount});

  @override
  Widget build(BuildContext context) {
    // 🔥 THE FIX: Wrapping the entire header content in SafeArea 
    // pushes it below the status bar, preventing overlap.
    return SafeArea(
      bottom: false, // Only apply padding to the top, not the bottom
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ⭐ Gradient Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.25),
                    Colors.orange.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // 📝 Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Interested Contacts',
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$contactCount contacts showing interest',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ContactsList extends StatelessWidget {
  final List<DriverContact> contacts;
  final ScrollController scrollController;
  final Function(DriverContact) onCallPressed;

  const _ContactsList({
    required this.contacts,
    required this.scrollController,
    required this.onCallPressed,
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
          ),
        );
      },
    );
  }
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
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.star_outline_rounded,
              size: 60,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Interested Contacts',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacts showing interest in subscription\nwill appear here',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.grey.shade500,
            ),
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
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}