import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class JobMatchingFeedbackModal extends StatefulWidget {
  final String driverName;
  final String transporterName;
  final Function(String callStatus, String callFeedback, String? remarks, String? matchStatus) onSubmit;

  const JobMatchingFeedbackModal({
    Key? key,
    required this.driverName,
    required this.transporterName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<JobMatchingFeedbackModal> createState() =>
      _JobMatchingFeedbackModalState();
}

class _JobMatchingFeedbackModalState extends State<JobMatchingFeedbackModal> {
  String? _selectedCallStatus;
  String? _selectedFeedback;
  String? _selectedMatchStatus;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _callStatusOptions = [
    'connected',
    'not_connected',
    'call_back',
  ];

  final Map<String, List<String>> _feedbackOptions = {
    'connected': [
      'Driver agreed for job',
      'Driver rejected job',
      'Driver wants more details',
      'Driver will call back',
      'Wrong number',
      'Not interested',
    ],
    'not_connected': [
      'Ringing / Call Busy',
      'Switched Off / Not Reachable',
      'Invalid number',
    ],
    'call_back': [
      'Call back in 1 hour',
      'Call back in 2 hours',
      'Call back tomorrow',
      'Call back next week',
    ],
  };

  final List<String> _matchStatusOptions = [
    'pending',
    'confirmed',
    'rejected',
  ];

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _selectedCallStatus != null && _selectedFeedback != null;
  }

  String _getCallStatusLabel(String status) {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'not_connected':
        return 'Not Connected';
      case 'call_back':
        return 'Call Back';
      default:
        return status;
    }
  }

  String _getMatchStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  void _handleSubmit() {
    if (!_canSubmit) return;

    final remarks = _remarksController.text.trim().isNotEmpty 
        ? _remarksController.text.trim() 
        : null;

    setState(() => _isSubmitting = true);
    widget.onSubmit(
      _selectedCallStatus!,
      _selectedFeedback!,
      remarks,
      _selectedMatchStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.phone_callback,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Matching Call Feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.driverName} ↔ ${widget.transporterName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.softGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Call Status Selection
              Text(
                'Call Status *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _callStatusOptions.map((status) {
                  final isSelected = _selectedCallStatus == status;
                  return ChoiceChip(
                    label: Text(_getCallStatusLabel(status)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCallStatus = selected ? status : null;
                        _selectedFeedback = null; // Reset feedback when status changes
                      });
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.accent,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Feedback Selection
              if (_selectedCallStatus != null) ...[
                Text(
                  'Feedback *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _feedbackOptions[_selectedCallStatus]!.map((feedback) {
                    final isSelected = _selectedFeedback == feedback;
                    return ChoiceChip(
                      label: Text(feedback),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFeedback = selected ? feedback : null;
                        });
                      },
                      selectedColor: AppColors.success,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.accent,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Match Status Selection (Optional)
              Text(
                'Match Status (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _matchStatusOptions.map((status) {
                  final isSelected = _selectedMatchStatus == status;
                  return ChoiceChip(
                    label: Text(_getMatchStatusLabel(status)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMatchStatus = selected ? status : null;
                      });
                    },
                    selectedColor: AppColors.info,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.accent,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Remarks
              Text(
                'Remarks (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.softGray.withValues(alpha: 0.3),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
