import 'package:flutter/material.dart';

class AttendanceDetailPage extends StatelessWidget {
  final String attendanceId;

  const AttendanceDetailPage({
    Key? key,
    required this.attendanceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Detail'),
      ),
      body: const Center(
        child: Text('Attendance Detail Page'),
      ),
    );
  }
}