import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class JobCallStatusSelectionModal extends StatefulWidget {
  final String transporterName;
  final Function(String status, String? feedback, String? remarks, bool closeJob) onStatusSelected;

  const JobCallStatusSelectionModal({
    super.key,
    required this.transporterName,
    required this.onStatusSelected,
  });

  @override
  State<JobCallStatusSelectionModal> createState() =>
      _JobCallStatusSelectionModalState();
}

class _JobCallStatusSelectionModalState
    extends State<JobCallStatusSelectionModal> {
  String? _selectedStatus;
  String? _selectedFeedback;
  bool _isSubmitting = false;
  final TextEditingController _remarksController = TextEditingController();

  final Map<String, List<String>> _feedbackOptions = {
    'Connected': [
      'Transporter Confirmed Job Details',
      'Transporter Wants to Modify Job Details',
      'Transporter Wants to Hold the Job',
      'Transporter Wants to Cancel the Job',
      'Transporter Busy – Requested Call Back',
      'Transporter Not Interested Anymore',
      'Transporter Shared Additional Information (Notes)',
      'Not a genuine Transporter',
    ],
    'Not Connected': [
      'Ringing/Call Busy',
      'Switched Off/ Not Reachable',
      'Wrong Number',
    ],
    'Call Back Later': [
      'Busy Right now',
      'Call Tomorrow',
      'Call in Evening',
      'Call After 2 Days',
    ],
  };

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedStatus == null || _selectedFeedback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both status and feedback'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if "Transporter Wants to Cancel the Job" is selected
    if (_selectedFeedback == 'Transporter Wants to Cancel the Job') {
      final shouldCloseJob = await _showCloseJobConfirmation();
      if (shouldCloseJob == true) {
        // User selected Yes - submit with closeJob = true
        setState(() => _isSubmitting = true);
        widget.onStatusSelected(
          _selectedStatus!,
          _selectedFeedback!,
          _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
          true, // closeJob = true
        );
      }
      // If No or dismissed, stay on the same screen - do nothing
      return;
    }
   if (_selectedFeedback == 'Not a genuine Transporter') {
      final shouldCloseJob = await _showCloseJobConfirmation();
      if (shouldCloseJob == true) {
        // User selected Yes - submit with closeJob = true
        setState(() => _isSubmitting = true);
        widget.onStatusSelected(
          _selectedStatus!,
          _selectedFeedback!,
          _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
          true, // closeJob = true
        );
      }
      // If No or dismissed, stay on the same screen - do nothing
      return;
    }


    setState(() => _isSubmitting = true);
    widget.onStatusSelected(
      _selectedStatus!,
      _selectedFeedback!,
      _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      false, // closeJob = false
    );
  }

  Future<bool?> _showCloseJobConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Close Job?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Do you want to close this job? This action will mark the job as closed.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'No',
              style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Yes, Close Job',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (no close button - must submit feedback)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Call Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        widget.transporterName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Required feedback indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Selection
            const Text(
              'Select Call Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusButtons(),
            const SizedBox(height: 24),

            // Feedback Selection
            if (_selectedStatus != null) ...[
              const Text(
                'Select Feedback',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeedbackOptions(),
              const SizedBox(height: 24),
              
              // Remarks Field - Always show when status is selected
              const Text(
                'Remarks (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional remarks...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: !_isSubmitting && _selectedFeedback != null
                    ? _handleSubmit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    return Column(
      children: _feedbackOptions.keys.map((status) {
        final isSelected = _selectedStatus == status;
        final colors = {
          'Connected': const Color(0xFF10B981),
          'Not Connected': const Color(0xFFEF4444),
          'Call Back Later': const Color(0xFFF59E0B),
        };
        final color = colors[status] ?? AppColors.primary;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedStatus = status;
              _selectedFeedback = null;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? color : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? color : const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackOptions() {
    final options = _feedbackOptions[_selectedStatus] ?? [];
    return Column(
      children: options.map((feedback) {
        final isSelected = _selectedFeedback == feedback;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFeedback = feedback;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_off,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF9CA3AF),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feedback,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
