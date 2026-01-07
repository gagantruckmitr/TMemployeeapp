import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';

class TransporterFeedbackModal extends StatefulWidget {
  final TransporterContact contact;
  final Function(CallFeedback) onFeedbackSubmitted;
  final String? referenceId;
  final int? callDuration;

  const TransporterFeedbackModal({
    super.key,
    required this.contact,
    required this.onFeedbackSubmitted,
    this.referenceId,
    this.callDuration,
  });

  @override
  State<TransporterFeedbackModal> createState() =>
      _TransporterFeedbackModalState();
}

class _TransporterFeedbackModalState extends State<TransporterFeedbackModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _feedbackAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _feedbackSlideAnimation;
  final ScrollController _scrollController = ScrollController();

  CallStatus? _selectedStatus;
  TransporterConnectedFeedback? _selectedTransporterFeedback;
  CallBackReason? _selectedCallBackReason;
  CallBackTime? _selectedCallBackTime;
  final TextEditingController _remarksController = TextEditingController();

  bool _showConnectedOptions = false;
  bool _showCallBackReasons = false;
  bool _showCallBackTimeOptions = false;
  bool _showCloseJobOption = false;
  bool? _closeJob;

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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _feedbackSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _feedbackAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _feedbackAnimationController.dispose();
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStatusSelected(CallStatus status) {
    final currentScrollPosition = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    setState(() {
      if (_selectedStatus == status) {
        _selectedStatus = null;
        _showConnectedOptions = false;
        _showCallBackReasons = false;
        _showCallBackTimeOptions = false;
      } else {
        _selectedStatus = status;
        _showConnectedOptions = status == CallStatus.connected;
        _showCallBackReasons = status == CallStatus.callBack;
        _showCallBackTimeOptions = status == CallStatus.callBackLater;
      }

      _selectedTransporterFeedback = null;
      _selectedCallBackReason = null;
      _selectedCallBackTime = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && currentScrollPosition > 0) {
        _scrollController.jumpTo(currentScrollPosition);
      }
    });

    _feedbackAnimationController.reset();
    if (_showConnectedOptions ||
        _showCallBackReasons ||
        _showCallBackTimeOptions) {
      _feedbackAnimationController.forward();
    }

    HapticFeedback.selectionClick();
  }

  void _onTransporterFeedbackSelected(TransporterConnectedFeedback feedback) {
    setState(() {
      _selectedTransporterFeedback = feedback;
      // Reset closeJob option - no longer used
      _showCloseJobOption = false;
      _closeJob = null;
    });

    HapticFeedback.selectionClick();
  }

  void _onCallBackReasonSelected(CallBackReason reason) {
    setState(() {
      _selectedCallBackReason = reason;
    });
    HapticFeedback.selectionClick();
  }

  void _onCallBackTimeSelected(CallBackTime time) {
    setState(() {
      _selectedCallBackTime = time;
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
      default:
        return Colors.grey;
    }
  }

  Color _getFeedbackColor(TransporterConnectedFeedback feedback) {
    switch (feedback) {
      case TransporterConnectedFeedback.agreeForSubscription:
      case TransporterConnectedFeedback.agreeForSubscriptionToday:
      case TransporterConnectedFeedback.agreeForSubscriptionTomorrow:
      case TransporterConnectedFeedback.alreadySubscribed:
        return Colors.green;
      case TransporterConnectedFeedback.needsHelpInProfile:
      case TransporterConnectedFeedback.doesntUnderstandApp:
      case TransporterConnectedFeedback.languageBarrier:
      case TransporterConnectedFeedback.wantsDemoVideo:
      case TransporterConnectedFeedback.internetIssueLowSpeed:
        return Colors.blue;
      case TransporterConnectedFeedback.willSubscribeLater:
      case TransporterConnectedFeedback.willSubscribeWhenDriversNeeded:
      case TransporterConnectedFeedback.wantsToThink:
      case TransporterConnectedFeedback.needLoad:
      case TransporterConnectedFeedback.needsDriverUrgently:
        return Colors.yellow.shade700;
      case TransporterConnectedFeedback.neitherTransporterNorDriver:
      case TransporterConnectedFeedback.driverButRegisteredAsTransporter:
      case TransporterConnectedFeedback.driverCabBus:
      case TransporterConnectedFeedback.notInterested:
      case TransporterConnectedFeedback.misbehave:
        return Colors.red;
      case TransporterConnectedFeedback.appIssue:
        return Colors.orange;
      case TransporterConnectedFeedback.wrongNumber:
      case TransporterConnectedFeedback.thirdPersonReceivedAskedToCallLater:
        return Colors.orange;
      case TransporterConnectedFeedback.others:
        return Colors.grey;
    }
  }

  bool _canSubmit() {
    if (_selectedStatus == null) return false;

    switch (_selectedStatus!) {
      case CallStatus.connected:
        if (_selectedTransporterFeedback == null) return false;
        // Only require Yes/No selection for "Close Job" option
        if (_showCloseJobOption && _closeJob == null) return false;
        return true;
      case CallStatus.callBack:
        return _selectedCallBackReason != null;
      case CallStatus.callBackLater:
        return _selectedCallBackTime != null;
      default:
        return false;
    }
  }

  void _submitFeedback() {
    if (!_canSubmit()) return;

    final feedback = CallFeedback(
      status: _selectedStatus!,
      transporterConnectedFeedback: _selectedTransporterFeedback,
      callBackReason: _selectedCallBackReason,
      callBackTime: _selectedCallBackTime,
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
      closeJob: _closeJob,
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
        decoration: BoxDecoration(
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
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactInfo(),
                    const SizedBox(height: 24),
                    _buildCallStatusSection(),
                    if (_showCloseJobOption) ...[
                      const SizedBox(height: 24),
                      _buildCloseJobSection(),
                    ],
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
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.15),
            AppTheme.accentOrange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_shipping,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transporter Call Feedback',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome Call - Select status',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
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
                widget.contact.name.isNotEmpty ? widget.contact.name.substring(0, 1).toUpperCase() : '?',
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
                  'Transporter • ${widget.contact.state}',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray),
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

        // Connected Status
        _buildStatusWithFeedback(
          'Connected',
          CallStatus.connected,
          _showConnectedOptions,
          _buildConnectedFeedbackOptions(),
        ),

        // Not Connected Status
        _buildStatusWithFeedback(
          'Not Connected',
          CallStatus.callBack,
          _showCallBackReasons,
          _buildCallBackReasonOptions(),
        ),

        // Call Back Later Status
        _buildStatusWithFeedback(
          'Call Back Later',
          CallStatus.callBackLater,
          _showCallBackTimeOptions,
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
        ...TransporterConnectedFeedback.values.map(
          (feedback) => _buildRadioOption(
            feedback.displayName,
            feedback,
            _selectedTransporterFeedback,
            _onTransporterFeedbackSelected,
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
            'Not Connected Reason',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.yellow.shade700,
            ),
          ),
        ),
        ...CallBackReason.values.map(
          (reason) => _buildRadioOption(
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
        ...CallBackTime.values.map(
          (time) => _buildRadioOption(
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
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.white,
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
                  ? Icon(Icons.check, color: AppTheme.white, size: 12)
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

  Widget _buildCloseJobSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_off, size: 18, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              'Do you want to close this job?',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCloseJobOption('Yes', true, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildCloseJobOption('No', false, Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildCloseJobOption(String title, bool value, Color color) {
    final isSelected = _closeJob == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _closeJob = value;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppTheme.gray.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  ? Icon(Icons.check, color: AppTheme.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTheme.bodyLarge.copyWith(
                color: isSelected ? color : AppTheme.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
        Row(
          children: [
            Icon(Icons.notes, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              'Remarks',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Optional',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _remarksController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Add any important details or notes...',
              hintStyle: AppTheme.bodyLarge.copyWith(
                color: AppTheme.gray.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: AppTheme.bodySmall.copyWith(
                color: AppTheme.gray,
                fontSize: 11,
              ),
            ),
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.black,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _canSubmit();

    return Column(
      children: [
        if (!canSubmit)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please select a status and provide required details',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: canSubmit ? _submitFeedback : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canSubmit ? Icons.check_circle : Icons.lock_outline,
                    color: AppTheme.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    canSubmit ? 'Submit Feedback' : 'Complete Required Fields',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
