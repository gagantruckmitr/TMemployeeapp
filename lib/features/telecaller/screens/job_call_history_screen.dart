import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:audioplayers/audioplayers.dart';

class JobCallHistoryScreen extends StatefulWidget {
  final List<dynamic> callHistory;
  final String jobId;

  const JobCallHistoryScreen({
    Key? key,
    required this.callHistory,
    required this.jobId,
  }) : super(key: key);

  @override
  State<JobCallHistoryScreen> createState() => _JobCallHistoryScreenState();
}

class _JobCallHistoryScreenState extends State<JobCallHistoryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _currentlyPlayingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRecording(String url) async {
    try {
      if (_currentlyPlayingUrl == url && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_currentlyPlayingUrl != url) {
          await _audioPlayer.stop();
          _currentlyPlayingUrl = url;
        }
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Call History - ${widget.jobId}',
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: widget.callHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No call history found for this job',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.callHistory.length,
              itemBuilder: (context, index) {
                return _buildCallLogCard(context, widget.callHistory[index]);
              },
            ),
    );
  }

  Widget _buildCallLogCard(BuildContext context, dynamic log) {
    final callTime = _formatDate(log['call_time']);
    final status = log['call_status'] ?? 'Unknown';
    final feedback = log['feedback'] ?? '';
    final remarks = log['remarks'] ?? '';
    final recordingUrl = log['recording_url'];

    final isPlayingThis = _currentlyPlayingUrl == recordingUrl && _isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date/Time and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  callTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),

            // Caller Name
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Caller: ${log['caller_name'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),

            // Duration & Recording
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${log['duration'] ?? '00:00'}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                if (recordingUrl != null &&
                    recordingUrl.toString().isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: isPlayingThis
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPlayingThis
                            ? Colors.red.shade200
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlayingThis ? Icons.pause : Icons.play_arrow,
                        color: isPlayingThis ? Colors.red : Colors.blue,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => _playRecording(recordingUrl),
                      tooltip: isPlayingThis ? 'Pause' : 'Play Recording',
                    ),
                  ),
                ],
              ],
            ),

            // Progress Bar (only if playing this item)
            if (_currentlyPlayingUrl == recordingUrl) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_duration.inMilliseconds > 0)
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            // Feedback
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'Feedback:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],

            // Remarks
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Remarks:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remarks,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('connected')) {
      color = Colors.green;
      icon = Icons.check_circle_outline;
    } else if (lowerStatus.contains('not connected') ||
        lowerStatus.contains('rejected')) {
      color = Colors.red;
      icon = Icons.cancel_outlined;
    } else if (lowerStatus.contains('busy')) {
      color = Colors.orange;
      icon = Icons.access_time;
    } else {
      color = Colors.grey;
      icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
