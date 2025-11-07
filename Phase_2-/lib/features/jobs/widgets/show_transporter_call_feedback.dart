import 'package:flutter/material.dart';
import 'dart:io';
import 'transporter_call_feedback_modal.dart';

Future<void> showTransporterCallFeedback({
  required BuildContext context,
  required String transporterTmid,
  required String transporterName,
  required String jobId,
  required Function(String callStatus, String? notes, File? recordingFile) onSubmit,
}) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TransporterCallFeedbackModal(
      transporterTmid: transporterTmid,
      transporterName: transporterName,
      jobId: jobId,
      onSubmit: onSubmit,
    ),
  );
}
