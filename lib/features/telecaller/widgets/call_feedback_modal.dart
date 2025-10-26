import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';

class CallFeedbackModal extends StatefulWidget {
  final DriverContact contact;
  final Function(CallFeedback) onFeedbackSubmitted;
  final String? referenceId;
  final int? callDuration;

  const CallFeedbackModal({
    super.key,
    required this.contact,
    required this.onFeedbackSubmitted,
    this.referenceId,
    this.callDuration,
  });

  @override
  State<CallFeedbackModal> createState() => _CallFeedbackModalState();
}

class _CallFeedbackModalState extends State<CallFeedbackModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _feedbackAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _feedbackSlideAnimation;
  
  CallStatus? _selectedStatus;
  ConnectedFeedback? _selectedConnectedFeedback;
  CallBackReason? _selectedCallBackReason;
  CallBackTime? _selectedCallBackTime;
  final TextEditingController _remarksController = TextEditingController();
  
  bool _showConnectedOptions = false;
  bool _showCallBackReasons = false;
  bool _showCallBackTimes = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.easeOut,
    ));
    
    _feedbackSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _feedbackAnimationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onStatusSelected(CallStatus status) {
    setState(() {
      // Toggle logic: if same status is selected, deselect it
      if (_selectedStatus == status) {
        _selectedStatus = null;
        _showConnectedOptions = false;
        _showCallBackReasons = false;
        _showCallBackTimes = false;
      } else {
        _selectedStatus = status;
        _showConnectedOptions = status == CallStatus.connected;
        _showCallBackReasons = status == CallStatus.callBack;
        _showCallBackTimes = status == CallStatus.callBackLater;
      }
      
      // Reset sub-selections when status changes
      _selectedConnectedFeedback = null;
      _selectedCallBackReason = null;
      _selectedCallBackTime = null;
    });
    
    // Animate feedback options
    _feedbackAnimationController.reset();
    if (_showConnectedOptions || _showCallBackReasons || _showCallBackTimes) {
      _feedbackAnimationController.forward();
    }
    
    HapticFeedback.selectionClick();
  }

  void _onCallBackReasonSelected(CallBackReason reason) {
    setState(() {
      _selectedCallBackReason = reason;
      _showCallBackTimes = true;
    });
    
    HapticFeedback.selectionClick();
  }

  void _onCallBackTimeSelected(CallBackTime time) {
    setState(() {
      _selectedCallBackTime = time;
    });
    
    HapticFeedback.selectionClick();
  }

  void _onConnectedFeedbackSelected(ConnectedFeedback feedback) {
    setState(() {
      _selectedConnectedFeedback = feedback;
    });
    
    HapticFeedback.selectionClick();
  }

  Color _getStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.connected:
        return Colors.green;
      case CallStatus.callBack:
        return Colors.yellow.shade700;
      case CallStatus.callBackLater:
        return Colors.blue;
      case CallStatus.notReachable:
        return Colors.orange;
      case CallStatus.notInterested:
        return Colors.red;
      case CallStatus.invalid:
        return Colors.black;
      case CallStatus.pending:
        return Colors.grey;
    }
  }

  Color _getFeedbackColor(dynamic feedback) {
    if (feedback is ConnectedFeedback) {
      switch (feedback) {
        case ConnectedFeedback.agreeForSubscriptionToday:
        case ConnectedFeedback.agreeForSubscriptionTomorrow:
          return Colors.green;
        case ConnectedFeedback.needsHelpInProfile:
        case ConnectedFeedback.doesntUnderstandApp:
        case ConnectedFeedback.languageBarrier:
        case ConnectedFeedback.wantsDemoVideo:
          return Colors.blue;
        case ConnectedFeedback.willSubscribeLater:
        case ConnectedFeedback.willSubscribeWhenNeedJob:
        case ConnectedFeedback.wantsToThink:
          return Colors.yellow.shade700;
        case ConnectedFeedback.notATruckDriver:
        case ConnectedFeedback.noMoney:
          return Colors.red;
        case ConnectedFeedback.appIssue:
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }
    return Colors.grey;
  }

  bool _canSubmit() {
    if (_selectedStatus == null) return false;
    
    switch (_selectedStatus!) {
      case CallStatus.connected:
        return _selectedConnectedFeedback != null;
      case CallStatus.callBack:
        return _selectedCallBackReason != null;
      case CallStatus.callBackLater:
        return _selectedCallBackTime != null;
      case CallStatus.pending:
      case CallStatus.notReachable:
      case CallStatus.notInterested:
      case CallStatus.invalid:
        return false;
    }
  }

  void _submitFeedback() {
    if (!_canSubmit()) return;
    
    final feedback = CallFeedback(
      status: _selectedStatus!,
      connectedFeedback: _selectedConnectedFeedback,
      callBackReason: _selectedCallBackReason,
      callBackTime: _selectedCallBackTime,
      remarks: _remarksController.text.trim().isEmpty 
          ? null 
          : _remarksController.text.trim(),
    );
    
    HapticFeedback.mediumImpact();
    widget.onFeedbackSubmitted(feedback);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactInfo(),
                    const SizedBox(height: 24),
                    _buildCallStatusSection(),
                    const SizedBox(height: 24),
                    _buildRemarksSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_callback,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Call Feedback',
            style: AppTheme.headingMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Close button removed - feedback must be submitted
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.accentOrange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                  AppTheme.accentOrange.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                widget.contact.name.substring(0, 1).toUpperCase(),
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  widget.contact.name,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.contact.company,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Call Status',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        
        // Connected Status with inline feedback
        _buildStatusWithFeedback(
          'Connected',
          CallStatus.connected,
          _showConnectedOptions,
          _buildConnectedFeedbackOptions(),
        ),
        
        // Call Back Status with inline feedback
        _buildStatusWithFeedback(
          'Call Back',
          CallStatus.callBack,
          _showCallBackReasons,
          _buildCallBackReasonOptions(),
        ),
        
        // Call Back Later Status with inline feedback
        _buildStatusWithFeedback(
          'Call Back Later',
          CallStatus.callBackLater,
          _showCallBackTimes,
          _buildCallBackTimeOptions(),
        ),
      ],
    );
  }

  Widget _buildStatusWithFeedback(
    String title,
    CallStatus status,
    bool showFeedback,
    Widget feedbackOptions,
  ) {
    return Column(
      children: [
        _buildRadioOption(
          title,
          status,
          _selectedStatus,
          _onStatusSelected,
          _getStatusColor(status),
        ),
        if (showFeedback) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 32, bottom: 8),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _feedbackSlideAnimation,
                child: feedbackOptions,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectedFeedbackOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Connected Feedback',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
        ),
        ...ConnectedFeedback.values.map((feedback) =>
          _buildRadioOption(
            feedback.displayName,
            feedback,
            _selectedConnectedFeedback,
            _onConnectedFeedbackSelected,
            _getFeedbackColor(feedback),
          ),
        ),
      ],
    );
  }

  Widget _buildCallBackReasonOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Call Back Reason',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.yellow.shade700,
            ),
          ),
        ),
        ...CallBackReason.values.map((reason) =>
          _buildRadioOption(
            reason.displayName,
            reason,
            _selectedCallBackReason,
            _onCallBackReasonSelected,
            Colors.yellow.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCallBackTimeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Call Back Time',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ),
        ...CallBackTime.values.map((time) =>
          _buildRadioOption(
            time.displayName,
            time,
            _selectedCallBackTime,
            _onCallBackTimeSelected,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption<T>(
    String title,
    T value,
    T? selectedValue,
    Function(T) onSelected,
    Color color,
  ) {
    final isSelected = selectedValue == value;
    
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.1)
              : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? color.withValues(alpha: 0.5)
                : AppTheme.gray.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppTheme.gray,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppTheme.white,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  color: isSelected ? color : AppTheme.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remarks (Optional)',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.gray.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: _remarksController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any additional notes...',
              hintStyle: AppTheme.bodyLarge.copyWith(
                color: AppTheme.gray.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _canSubmit();
    
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: canSubmit ? _submitFeedback : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: canSubmit 
                ? AppTheme.primaryGradient
                : LinearGradient(
                    colors: [
                      AppTheme.gray.withValues(alpha: 0.3),
                      AppTheme.gray.withValues(alpha: 0.2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canSubmit ? AppTheme.buttonShadow : [],
          ),
          child: Center(
            child: Text(
              'Submit Feedback',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}