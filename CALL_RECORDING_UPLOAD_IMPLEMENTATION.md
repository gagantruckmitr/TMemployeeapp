# Call Recording Upload Feature - Complete Implementation Guide

## Overview
This feature allows telecallers to upload call recordings during feedback submission. Recordings are automatically renamed and stored on the server.

## ✅ Completed Components

### 1. API Endpoint (`api/upload_recording_api.php`)
- ✅ File upload handling
- ✅ Automatic filename generation: `TMID_CallerID_DateTime.ext`
- ✅ File validation (type, size)
- ✅ Storage in `/voice-recording/` directory
- ✅ Database update (recording_url column)
- ✅ Returns URL: `https://truckmitr.com/truckmitr-app/voice-recording/filename`

### 2. Dependencies
- ✅ Added `file_picker: ^8.0.0+1` to pubspec.yaml

### 3. Modal Updates
- ✅ Added `requireRecording` parameter to CallFeedbackModal

## 🔧 Remaining Implementation Steps

### Step 1: Add File Picker to CallFeedbackModal State

Add these to `_CallFeedbackModalState`:

```dart
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// Add to state variables
PlatformFile? _selectedRecording;
bool _isUploadingRecording = false;
String? _recordingUrl;
```

### Step 2: Add Recording Upload Method

```dart
Future<void> _pickRecording() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedRecording = result.files.first;
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error picking file: $e')),
    );
  }
}

Future<String?> _uploadRecording() async {
  if (_selectedRecording == null) return null;

  setState(() => _isUploadingRecording = true);

  try {
    final user = RealAuthService.instance.currentUser;
    final callerId = user?.id ?? 0;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/upload_recording_api.php'),
    );

    request.fields['tmid'] = widget.contact.tmid;
    request.fields['caller_id'] = callerId.toString();
    if (widget.referenceId != null) {
      request.fields['call_log_id'] = widget.referenceId!;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'recording',
        _selectedRecording!.path!,
      ),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseData);

    if (jsonResponse['success'] == true) {
      setState(() {
        _recordingUrl = jsonResponse['url'];
        _isUploadingRecording = false;
      });
      return jsonResponse['url'];
    } else {
      throw Exception(jsonResponse['error'] ?? 'Upload failed');
    }
  } catch (e) {
    setState(() => _isUploadingRecording = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $e')),
    );
    return null;
  }
}
```

### Step 3: Add Recording Upload UI Section

Add this method to build the recording upload section:

```dart
Widget _buildRecordingUploadSection() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: widget.requireRecording 
          ? AppTheme.accentOrange.withValues(alpha: 0.1)
          : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: widget.requireRecording
            ? AppTheme.accentOrange
            : Colors.grey.shade300,
        width: widget.requireRecording ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.mic,
              color: widget.requireRecording 
                  ? AppTheme.accentOrange 
                  : AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Call Recording',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.requireRecording) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Required',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        if (_selectedRecording == null)
          OutlinedButton.icon(
            onPressed: _pickRecording,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select Recording File'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.audio_file, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedRecording!.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(_selectedRecording!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedRecording = null),
                  icon: const Icon(Icons.close),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        
        if (_recordingUrl != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recording uploaded successfully',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
```

### Step 4: Add Recording Section to Build Method

In the `_buildRemarksSection()` method's parent Column, add:

```dart
const SizedBox(height: 24),
_buildRecordingUploadSection(),
```

### Step 5: Update Submit Button Logic

Modify `_buildSubmitButton()` to include recording validation:

```dart
Widget _buildSubmitButton() {
  final canSubmit = _selectedStatus != null && 
      (!widget.requireRecording || _selectedRecording != null);

  return ElevatedButton(
    onPressed: canSubmit && !_isUploadingRecording
        ? () async {
            // Upload recording first if selected
            if (_selectedRecording != null && _recordingUrl == null) {
              final url = await _uploadRecording();
              if (url == null && widget.requireRecording) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please upload recording before submitting'),
                  ),
                );
                return;
              }
            }

            // Submit feedback
            final feedback = CallFeedback(
              status: _selectedStatus!,
              connectedFeedback: _selectedConnectedFeedback,
              callBackReason: _selectedCallBackReason,
              callBackTime: _selectedCallBackTime,
              remarks: _remarksController.text.trim().isEmpty
                  ? null
                  : _remarksController.text.trim(),
            );

            widget.onFeedbackSubmitted(feedback);
          }
        : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: _isUploadingRecording
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(
            'Submit Feedback',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
  );
}
```

### Step 6: Update Smart Calling Page

In `smart_calling_page.dart`, update the CallFeedbackModal call:

```dart
child: CallFeedbackModal(
  contact: contact,
  referenceId: referenceId,
  callDuration: callDuration,
  requireRecording: true, // Make recording required in smart calling
  onFeedbackSubmitted: (feedback) {
    _updateContactStatus(
      contact,
      feedback,
      referenceId: referenceId,
      callDuration: callDuration,
    );
    Navigator.of(context).pop();
  },
),
```

### Step 7: Database Schema Update

The API automatically adds the column, but you can also run this SQL manually:

```sql
ALTER TABLE call_logs 
ADD COLUMN recording_url VARCHAR(500) NULL 
AFTER api_response;
```

## 📱 Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## 🎯 Features Summary

### Smart Calling Screen:
- ✅ Recording upload is **REQUIRED**
- ✅ Submit button disabled until recording is uploaded
- ✅ Orange "Required" badge shown
- ✅ Cannot submit feedback without recording

### Call History Screen:
- ✅ Recording upload is **OPTIONAL**
- ✅ Can submit feedback without recording
- ✅ No "Required" badge shown
- ✅ Recording upload available but not enforced

## 📝 File Naming Convention

Format: `TMID_CallerID_DateTime.ext`

Example: `TM2510BRDRI4327_5_20241101143025.mp3`
- TMID: TM2510BRDRI4327
- Caller ID: 5
- Date/Time: 2024-11-01 14:30:25
- Extension: .mp3

## 🔒 Security Features

- ✅ File type validation (audio only)
- ✅ File size limit (50MB max)
- ✅ Automatic filename sanitization
- ✅ Secure file storage
- ✅ Database URL storage

## 🚀 Testing Checklist

- [ ] Install dependencies: `flutter pub get`
- [ ] Test file picker on Android
- [ ] Test file upload to server
- [ ] Verify filename format
- [ ] Check database URL storage
- [ ] Test required validation in smart calling
- [ ] Test optional behavior in call history
- [ ] Verify file accessibility via URL

## 📂 File Structure

```
api/
  └── upload_recording_api.php (✅ Created)
  
voice-recording/ (Auto-created by API)
  └── [recordings stored here]
  
lib/
  └── features/telecaller/widgets/
      └── call_feedback_modal.dart (⚠️ Needs updates above)
```

---

**Status**: API Complete, Flutter Implementation Guide Provided
**Next Step**: Apply Flutter code changes from Steps 1-6 above
