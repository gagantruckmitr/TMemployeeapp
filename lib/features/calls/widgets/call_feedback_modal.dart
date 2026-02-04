import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/phase2_auth_service.dart';

class CallFeedbackModal extends StatefulWidget {
  final String userType; // 'transporter' or 'driver'
  final String userName;
  final String userTmid;
  final String? transporterTmid;
  final String? jobId;
  final bool showRecordingUpload; // Show/hide the recording upload section
  final Function(String feedback, String matchStatus, String notes) onSubmit;
  // Optional: callback that also passes the recording file (for job matching)
  final Function(
    String feedback,
    String matchStatus,
    String notes,
    File? recordingFile,
  )?
  onSubmitWithRecording;

  const CallFeedbackModal({
    super.key,
    required this.userType,
    required this.userName,
    required this.userTmid,
    this.transporterTmid,
    this.jobId,
    this.showRecordingUpload =
        true, // Default to true for backward compatibility
    required this.onSubmit,
    this.onSubmitWithRecording,
  });

  @override
  State<CallFeedbackModal> createState() => _CallFeedbackModalState();
}

class _CallFeedbackModalState extends State<CallFeedbackModal> {
  String? _selectedFeedback;
  String?
  _selectedFeedbackCategory; // Track which category (Connected, Not Connected, Call Back Later)
  String? _selectedMatchStatus;
  final TextEditingController _notesController = TextEditingController();
  File? _selectedRecordingFile;
  String? _selectedRecordingName;
  bool _isSubmitting = false;

  // Feedback options for each category
  final Map<String, List<String>> _feedbackOptions = {
    'Connected': [
      'Driver Interested',
      'Driver Not Interested',
      'Driver Already Booked / Busy',
      'Driver Does Not Work on That Route',
      'Driver Rate Mismatch',
      'Vehicle Not Available',
      'Vehicle Type Not Matching',
      'Driver Wants More Details',
      'Driver Wants to Speak to Transporter',
      'Driver Wants Call Back Later',
      'Driver Requested Callback on WhatsApp',
      'Interview Done',
    ],
    'Not Connected': [
      'Ringing – No Answer',
      'Switched Off',
      'Not Reachable',
      'Call Disconnected',
      'Number Busy',
      'Wrong Number',
      'Third Person Received – Asked to Call Later',
    ],
    'Call Back Later': [
      'Busy Right Now',
      'Call Tomorrow Morning',
      'Call in Evening',
      'Call After 2 Days',
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
        allowedExtensions: [
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
          'flac',
          'wma',
          'amr',
          'opus',
          '3gp',
        ],
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
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    // Validate category selection
    if (_selectedFeedbackCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a call status'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Validate feedback option selection
    if (_selectedFeedback == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a feedback option'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Validate call remarks for Connected and Call Back Later categories
    final isConnected = _selectedFeedbackCategory == 'Connected';
    final isCallBackLater = _selectedFeedbackCategory == 'Call Back Later';
    final remarksRequired = isConnected || isCallBackLater;

    if (remarksRequired && _notesController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Call Remarks is mandatory for $_selectedFeedbackCategory category',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build proper feedback format with category prefix
      String properFeedback = _selectedFeedback!;
      if (_selectedFeedbackCategory != null) {
        properFeedback = '$_selectedFeedbackCategory: $_selectedFeedback';
      }

      // Debug: Log recording file state
      print('📎 CallFeedbackModal _submitFeedback:');
      print(
        '   _selectedRecordingFile: ${_selectedRecordingFile?.path ?? "null"}',
      );
      print('   _selectedRecordingName: $_selectedRecordingName');
      print(
        '   onSubmitWithRecording provided: ${widget.onSubmitWithRecording != null}',
      );

      // If onSubmitWithRecording is provided, use it to pass the recording file
      if (widget.onSubmitWithRecording != null) {
        print('   → Calling onSubmitWithRecording with recording file');
        widget.onSubmitWithRecording!(
          properFeedback,
          _selectedMatchStatus ?? '',
          _notesController.text,
          _selectedRecordingFile,
        );
      } else {
        // First submit feedback to create/update the call log entry
        widget.onSubmit(
          properFeedback,
          _selectedMatchStatus ?? '',
          _notesController.text,
        );
      }

      // Wait a moment for the feedback to be saved
      await Future.delayed(const Duration(milliseconds: 500));

      // Then upload recording if selected
      if (_selectedRecordingFile != null && widget.jobId != null) {
        try {
          final callerId = await Phase2AuthService.getUserId();

          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
              '${ApiConfig.baseUrl}/phase2_upload_driver_recording_api.php',
            ),
          );

          request.files.add(
            await http.MultipartFile.fromPath(
              'recording',
              _selectedRecordingFile!.path,
            ),
          );

          request.fields['job_id'] = widget.jobId!;
          request.fields['caller_id'] = callerId.toString();

          // Support both driver and transporter recordings
          if (widget.userType == 'driver') {
            request.fields['driver_tmid'] = widget.userTmid;
          } else if (widget.userType == 'transporter') {
            request.fields['transporter_tmid'] = widget.userTmid;
          }

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData['success'] == true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recording uploaded successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } else {
              throw Exception(responseData['message'] ?? 'Upload failed');
            }
          } else {
            throw Exception('Server error: ${response.statusCode}');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recording upload failed: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from closing modal
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Removed drag handle to prevent dismissal
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Call Feedback',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.userName} • ${widget.userTmid}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Removed close button to prevent dismissal without feedback
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Call Status with expandable options
                    const Text(
                      '1. Call Status & Feedback',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Connected Section
                    _buildCategoryWithOptions(
                      'Connected',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),

                    // Not Connected Section
                    _buildCategoryWithOptions(
                      'Not Connected',
                      Icons.phone_disabled_outlined,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    // Call Back Later Section
                    _buildCategoryWithOptions(
                      'Call Back Later',
                      Icons.schedule_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(height: 24),

                    // Step 2: Match Status
                    const Text(
                      '2. Match Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMatchStatusChip('Selected'),
                        _buildMatchStatusChip('Not Selected'),
                        _buildMatchStatusChip('Pending'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Step 3: Call Remarks
                    Row(
                      children: [
                        const Text(
                          '3. Call Remarks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGray,
                          ),
                        ),
                        if (_selectedFeedbackCategory == 'Connected' ||
                            _selectedFeedbackCategory == 'Call Back Later')
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            _selectedFeedbackCategory == 'Connected' ||
                                _selectedFeedbackCategory == 'Call Back Later'
                            ? 'Enter call remarks (required for this category)...'
                            : 'Enter any remarks or follow-up details...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.jobId != null && widget.showRecordingUpload) ...[
                      const Text(
                        'Call Recording (Optional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            if (_selectedRecordingName != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.audiotrack,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedRecordingName!,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _selectedRecordingFile = null;
                                        _selectedRecordingName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Recording will be uploaded when you submit feedback',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              OutlinedButton.icon(
                                onPressed: _pickRecording,
                                icon: const Icon(Icons.attach_file, size: 18),
                                label: const Text('Select Recording File'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select audio file from your device storage',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Show validation message if remarks are required but empty
                        if ((_selectedFeedbackCategory == 'Connected' ||
                                _selectedFeedbackCategory ==
                                    'Call Back Later') &&
                            _selectedFeedback != null &&
                            _notesController.text.trim().isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Call Remarks is mandatory for $_selectedFeedbackCategory',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Centered Submit Button
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: ElevatedButton(
                              onPressed:
                                  _selectedFeedbackCategory != null &&
                                      _selectedFeedback != null &&
                                      !_isSubmitting
                                  ? _submitFeedback
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _selectedRecordingFile != null
                                          ? 'Submit Feedback & Upload Recording'
                                          : 'Submit Feedback',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryWithOptions(
    String category,
    IconData icon,
    Color color,
  ) {
    final isCategorySelected = _selectedFeedbackCategory == category;
    final options = _feedbackOptions[category]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCategorySelected ? color : Colors.grey.shade300,
          width: isCategorySelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Category Header (Radio Button)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_selectedFeedbackCategory == category) {
                  // Collapse if already selected
                  _selectedFeedbackCategory = null;
                  _selectedFeedback = null;
                } else {
                  // Expand this category
                  _selectedFeedbackCategory = category;
                  _selectedFeedback = null;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCategorySelected
                    ? color.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCategorySelected
                            ? color
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isCategorySelected ? color : Colors.transparent,
                    ),
                    child: isCategorySelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    icon,
                    color: isCategorySelected ? color : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCategorySelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCategorySelected
                            ? color
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Icon(
                    isCategorySelected ? Icons.expand_less : Icons.expand_more,
                    color: isCategorySelected ? color : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Feedback Options (Expanded below when selected)
          if (isCategorySelected) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: options.map((option) {
                  final isOptionSelected = _selectedFeedback == option;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFeedback = option;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isOptionSelected
                            ? color.withOpacity(0.15)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOptionSelected
                              ? color
                              : Colors.grey.shade200,
                          width: isOptionSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOptionSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isOptionSelected
                                ? color
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isOptionSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isOptionSelected
                                    ? color
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchStatusChip(String label) {
    final isSelected = _selectedMatchStatus == label;
    final color = label == 'Selected'
        ? Colors.green
        : label == 'Not Selected'
        ? Colors.red
        : Colors.orange;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMatchStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
