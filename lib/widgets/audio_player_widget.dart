import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AudioPlayerWidget extends StatelessWidget {
  final String? recordingUrl;
  final String label;

  const AudioPlayerWidget({
    super.key,
    required this.recordingUrl,
    this.label = 'Call Recording',
  });

  Future<void> _playRecording(BuildContext context) async {
    if (recordingUrl == null || recordingUrl!.isEmpty) return;

    try {
      final uri = Uri.parse(recordingUrl!);

      // Launch in external browser/app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      // Show error with copy option
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not open recording. URL copied to clipboard.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );

        // Copy URL to clipboard
        await Clipboard.setData(ClipboardData(text: recordingUrl!));
      }
    }
  }

  void _showRecordingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Call Recording',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.play_circle, color: Colors.blue.shade700),
              title: const Text('Play in Browser'),
              subtitle: const Text('Open recording in web browser'),
              onTap: () {
                Navigator.pop(context);
                _playRecording(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: Colors.grey.shade700),
              title: const Text('Copy URL'),
              subtitle: const Text('Copy recording link to clipboard'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: recordingUrl!));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recording URL copied to clipboard'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (recordingUrl == null || recordingUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _playRecording(context),
      onLongPress: () => _showRecordingOptions(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.audiotrack,
                color: Colors.blue.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to play • Long press for options',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_filled,
              color: Colors.blue.shade700,
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
