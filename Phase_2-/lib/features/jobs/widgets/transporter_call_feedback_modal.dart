import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TransporterCallFeedbackModal extends StatefulWidget {
  final String transporterTmid;
  final String transporterName;
  final String jobId;
  final Function(String callStatus, String? notes) onSubmit;

  const TransporterCallFeedbackModal({
    Key? key,
    required this.transporterTmid,
    required this.transporterName,
    required this.jobId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<TransporterCallFeedbackModal> createState() =>
      _TransporterCallFeedbackModalState();
}

class _TransporterCallFeedbackModalState
    extends State<TransporterCallFeedbackModal> {
  String? _selectedMainStatus;
  String? _selectedSubStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, List<String>> _statusOptions = {
    'Connected': [
      'Call Back Later',
      'Details Received',
      'Not a Genuine Transporter',
      'He is Driver, mistakenly registered as Transporter',
    ],
    'Not Connected': [
      'Ringing / Call Busy',
      'Switched Off / Not Reachable',
    ],
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedMainStatus != null &&
      _selectedSubStatus != null;

  void _handleSubmit() {
    if (!_canSubmit) return;

    final callStatus = '$_selectedMainStatus: $_selectedSubStatus';
    final notes = _notesController.text.trim().isNotEmpty 
        ? _notesController.text.trim() 
        : null;

    setState(() => _isSubmitting = true);
    widget.onSubmit(callStatus, notes);
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_callback,
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
                        'Call Feedback',
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Status Selection
            const Text(
              'Call Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMainStatusButton('Connected', Icons.check_circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMainStatusButton(
                      'Not Connected', Icons.phone_missed),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sub Status Selection
            if (_selectedMainStatus != null) ...[
              const Text(
                'Select Option',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              ..._statusOptions[_selectedMainStatus]!
                  .map((option) => _buildSubStatusOption(option)),
              const SizedBox(height: 24),
            ],

            // Optional Feedback Notes (for all options except Details Received)
            if (_selectedSubStatus != null && _selectedSubStatus != 'Details Received') ...[
              const Text(
                'Feedback Notes (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes...',
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

            // Submit Button (only for non-Details Received options)
            if (_selectedSubStatus != null && _selectedSubStatus != 'Details Received')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: !_isSubmitting ? _handleSubmit : null,
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
                          'Submit Feedback',
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

  Widget _buildMainStatusButton(String status, IconData icon) {
    final isSelected = _selectedMainStatus == status;
    final color = status == 'Connected'
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMainStatus = status;
          _selectedSubStatus = null;
          _notesController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF9CA3AF),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStatusOption(String option) {
    final isSelected = _selectedSubStatus == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubStatus = option;
          if (option != 'Details Received') {
            _notesController.clear();
          }
        });
        
        // If "Details Received" is selected, immediately submit and open job brief form
        if (option == 'Details Received' && _selectedMainStatus != null) {
          final callStatus = '$_selectedMainStatus: $option';
          widget.onSubmit(callStatus, null);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 14,
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
  }
}
