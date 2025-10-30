import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaveBreakManagementWidget extends StatefulWidget {
  final int telecallerId;

  const LeaveBreakManagementWidget({super.key, required this.telecallerId});

  @override
  State<LeaveBreakManagementWidget> createState() =>
      _LeaveBreakManagementWidgetState();
}

class _LeaveBreakManagementWidgetState
    extends State<LeaveBreakManagementWidget> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return const SizedBox.shrink();
  }
}
