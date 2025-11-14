import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../models/smart_calling_models.dart';

class CallFeedbackModal extends StatefulWidget {
  final DriverContact contact;
  final Function(CallFeedback) onFeedbackSubmitted;
  final String? referenceId;
  final int? callDuration;
  final bool allowDismiss; // Allow closing without feedback (for call history)
  final bool requireRecording; // Require recording upload (for smart calling)

  const CallFeedbackModal({
    super.key,
    required this.contact,
    required this.onFeedbackSubmitted,
    this.referenceId,
    this.callDuration,
    this.allowDismiss = false, // Default to false (smart calling behavior)
    this.requireRecording = false, // Default to false (call history behavior)
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
  final ScrollController _scrollController = ScrollController();

  CallStatus? _selectedStatus;
  ConnectedFeedback? _selectedConnectedFeedback;
  CallBackReason? _selectedCallBackReason;
  CallBackTime? _selectedCallBackTime;
  final TextEditingController _remarksController = TextEditingController();

  bool _showConnectedOptions = false;
  bool _showCallBackReasons = false;
  bool _showCallBackTimes = false;

  // Recording upload state
  File? _selectedRecording;
  String? _recordingFileName;
  bool _isPickingFile = false;

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
    // Preserve current scroll position
    final currentScrollPosition = _scrollController.hasClients 
        ? _scrollController.position.pixels 
        : 0.0;

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

    // Restore scroll position after rebuild to prevent auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && currentScrollPosition > 0) {
        _scrollController.jumpTo(currentScrollPosition);
      }
    });

    // Animate feedback options without scrolling
    _feedbackAnimationController.reset();
    if (_showConnectedOptions || _showCallBackReasons || _showCallBackTimes) {
      _feedbackAnimationController.forward();
    }

    HapticFeedback.selectionClick();
  }

  void _onCallBackReasonSelected(CallBackReason reason) {
    setState(() {
      _selectedCallBackReason = reason;
      // Don't auto-expand Call Back Later section
      // User must explicitly select "Call Back Later" status
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
        case ConnectedFeedback.alreadySubscribed:
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

  Future<void> _pickRecording() async {
    if (_isPickingFile) return;

    setState(() {
      _isPickingFile = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 50MB)
        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 50MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedRecording = file;
          _recordingFileName = result.files.single.name;
        });

        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isPickingFile = false;
      });
    }
  }

  void _removeRecording() {
    setState(() {
      _selectedRecording = null;
      _recordingFileName = null;
    });
    HapticFeedback.lightImpact();
  }

  bool _canSubmit() {
    if (_selectedStatus == null) return false;

    // If recording is required and not uploaded, can't submit
    if (widget.requireRecording && _selectedRecording == null) {
      return false;
    }

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
      recordingFile: _selectedRecording,
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
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const SizedBox(height: 24),
                    _buildRecordingUploadSection(),
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
              Icons.phone_callback,
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
                  'Call Feedback',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Select status and provide details',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Close button (only shown if allowDismiss is true)
          if (widget.allowDismiss)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              color: AppTheme.gray,
              tooltip: 'Close',
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
                if (widget.contact.company.isNotEmpty &&
                    !widget.contact.company.toLowerCase().contains('unknown'))
                  Text(
                    widget.contact.company,
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

        // Connected Status with inline feedback
        _buildStatusWithFeedback(
          'Connected',
          CallStatus.connected,
          _showConnectedOptions,
          _buildConnectedFeedbackOptions(),
        ),

        // Not Connected Status with inline feedback
        _buildStatusWithFeedback(
          'Not Connected',
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
        ...ConnectedFeedback.values.map(
          (feedback) => _buildRadioOption(
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

  Widget _buildRecordingUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mic, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              'Call Recording',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.requireRecording
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.gray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.requireRecording ? 'Required' : 'Optional',
                style: AppTheme.bodySmall.copyWith(
                  color: widget.requireRecording ? Colors.red : AppTheme.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedRecording == null)
          GestureDetector(
            onTap: _isPickingFile ? null : _pickRecording,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.requireRecording
                      ? Colors.red.withValues(alpha: 0.3)
                      : AppTheme.primaryBlue.withValues(alpha: 0.2),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_isPickingFile)
                    const CircularProgressIndicator()
                  else ...[
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Call Recording',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select audio file (Max 50MB)',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.audio_file,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recordingFileName ?? 'Recording',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to upload',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeRecording,
                  icon: const Icon(Icons.close),
                  color: Colors.red,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
      ],
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
              hintText:
                  'Add any important details, concerns, or follow-up notes...',
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
