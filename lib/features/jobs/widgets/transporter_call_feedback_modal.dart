import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';

class TransporterCallFeedbackModal extends StatefulWidget {
  final String transporterTmid;
  final String transporterName;
  final String jobId;
  final Function(String callStatus, String? notes, File? recordingFile) onSubmit;

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
  File? _selectedRecordingFile;
  String? _selectedRecordingName;
  bool? _closeJobConfirmation;

  final Map<String, List<String>> _statusOptions = {
    'Connected': [
      'Match Making Done',
      'Call Back Later',
      'Details Received',
      'Not a Transporter',
      'He is Driver, mistakenly registered as Transporter',
      'Hire from other source',
      'Hired from TruckMitr',
      'Close Job',
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

  Future<void> _pickRecording() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'amr', 'opus', '3gp'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedRecordingFile = File(result.files.single.path!);
          _selectedRecordingName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeRecording() {
    setState(() {
      _selectedRecordingFile = null;
      _selectedRecordingName = null;
    });
  }

  bool get _canSubmit {
    if (_selectedMainStatus == null || _selectedSubStatus == null) return false;
    
    // For "Close Job" option, require Yes/No confirmation
    if (_selectedSubStatus == 'Close Job' && _closeJobConfirmation == null) {
      return false;
    }
    
    // For "Not a Transporter" and "He is Driver..." auto-close job
    return true;
  }
  
  bool get _shouldShowCloseJobConfirmation {
    return _selectedSubStatus == 'Close Job';
  }

  void _handleSubmit() {
    print('=== MODAL _handleSubmit CALLED ===');
    print('_canSubmit: $_canSubmit');
    print('_selectedMainStatus: $_selectedMainStatus');
    print('_selectedSubStatus: $_selectedSubStatus');
    print('_closeJobConfirmation: $_closeJobConfirmation');
    
    if (!_canSubmit) {
      print('✗ Cannot submit - _canSubmit is false');
      return;
    }

    // For "Close Job" option, only send it if user selected "Yes"
    String finalSubStatus = _selectedSubStatus!;
    if (_selectedSubStatus == 'Close Job' && _closeJobConfirmation == false) {
      // User selected "No" for closing job, so don't send "Close Job" feedback
      finalSubStatus = 'Call Back Later'; // Change to a non-closing status
      print('Changed Close Job to Call Back Later (user selected No)');
    }

    final callStatus = '$_selectedMainStatus: $finalSubStatus';
    final notes = _notesController.text.trim().isNotEmpty 
        ? _notesController.text.trim() 
        : null;

    print('Final call status: $callStatus');
    print('Notes: $notes');
    print('Recording file: ${_selectedRecordingFile?.path}');
    print('Calling widget.onSubmit...');

    setState(() => _isSubmitting = true);
    widget.onSubmit(callStatus, notes, _selectedRecordingFile);
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
              _buildSubStatusGrid(_statusOptions[_selectedMainStatus]!),
              const SizedBox(height: 24),
            ],

            // Close Job Confirmation (only for "Close Job" option)
            if (_shouldShowCloseJobConfirmation) ...[
              const Text(
                'Do you want to close this job?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCloseJobOption('Yes', true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCloseJobOption('No', false),
                  ),
                ],
              ),
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
              const SizedBox(height: 20),

              // Call Recording Upload Section
              const Text(
                'Call Recording (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              
              if (_selectedRecordingFile == null)
                GestureDetector(
                  onTap: _pickRecording,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload Call Recording',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to select audio file',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.audiotrack,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRecordingName!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _removeRecording,
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF9CA3AF),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
                  onPressed: !_isSubmitting ? () {
                    print('=== SUBMIT BUTTON PRESSED ===');
                    print('_isSubmitting: $_isSubmitting');
                    print('_canSubmit: $_canSubmit');
                    _handleSubmit();
                  } : null,
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

  Widget _buildSubStatusGrid(List<String> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5, // Adjust for slim appearance
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildSubStatusOption(options[index]);
      },
    );
  }

  Widget _buildSubStatusOption(String option) {
    final isSelected = _selectedSubStatus == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubStatus = option;
          _closeJobConfirmation = null; // Reset confirmation when changing option
          if (option != 'Details Received') {
            _notesController.clear();
          }
        });
        
        // If "Details Received" is selected, immediately submit and open job brief form
        if (option == 'Details Received' && _selectedMainStatus != null) {
          final callStatus = '$_selectedMainStatus: $option';
          widget.onSubmit(callStatus, null, null);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : const Color(0xFF9CA3AF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF374151),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseJobOption(String title, bool value) {
    final isSelected = _closeJobConfirmation == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _closeJobConfirmation = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (value ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1))
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? (value ? Colors.red : Colors.green)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected
                  ? (value ? Colors.red : Colors.green)
                  : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (value ? Colors.red : Colors.green)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
