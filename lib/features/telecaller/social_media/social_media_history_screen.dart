import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/social_media_feedback_service.dart';
import '../widgets/tab_page_header.dart';
import '../../../widgets/audio_player_widget.dart';

class SocialMediaHistoryScreen extends StatefulWidget {
  const SocialMediaHistoryScreen({super.key});

  @override
  State<SocialMediaHistoryScreen> createState() => _SocialMediaHistoryScreenState();
}

class _SocialMediaHistoryScreenState extends State<SocialMediaHistoryScreen> {
  final SocialMediaFeedbackService _service = SocialMediaFeedbackService.instance;
  final DateFormat _dateFormat = DateFormat('d MMM yyyy • h:mm a');

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.fetchCallHistory();
      if (!mounted) return;
      setState(() {
        _history = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final results = await _service.fetchCallHistory();
      if (!mounted) return;
      setState(() {
        _history = results;
        _isRefreshing = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _error = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $error'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _isLoading
        ? 'Loading call history...'
        : _error != null
            ? 'Tap refresh to try again.'
            : _history.isEmpty
                ? 'No call history yet.'
                : '${_history.length} calls made';

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Social Media Call History',
          style: AppTheme.headingMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          TelecallerTabHeader(
            icon: Icons.history,
            iconColor: AppTheme.accentPurple,
            title: 'Call History',
            subtitle: subtitle,
            trailing: TelecallerHeaderActionButton(
              isLoading: _isRefreshing,
              onPressed: _refresh,
              icon: Icons.refresh_rounded,
              color: AppTheme.accentPurple,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const _LoadingView()
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _loadHistory)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: AppTheme.accentPurple,
                        child: _history.isEmpty
                            ? const _EmptyView()
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _history.length,
                                itemBuilder: (context, index) {
                                  final call = _history[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index < _history.length - 1 ? 16 : 0,
                                    ),
                                    child: _CallHistoryCard(
                                      call: call,
                                      dateFormat: _dateFormat,
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CallHistoryCard extends StatelessWidget {
  const _CallHistoryCard({
    required this.call,
    required this.dateFormat,
  });

  final Map<String, dynamic> call;
  final DateFormat dateFormat;

  Color _sourceColor() {
    final source = call['source']?.toString().toLowerCase() ?? '';
    switch (source) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return AppTheme.accentPurple;
    }
  }

  IconData _sourceIcon() {
    final source = call['source']?.toString().toLowerCase() ?? '';
    switch (source) {
      case 'facebook':
        return Icons.facebook;
      case 'whatsapp':
        return Icons.chat;
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.tag;
      default:
        return Icons.public;
    }
  }

  Color _feedbackColor() {
    final feedback = call['feedback']?.toString().toLowerCase() ?? '';
    if (feedback.contains('interested') || feedback.contains('connected')) {
      return AppTheme.success;
    } else if (feedback.contains('not interested') || feedback.contains('rejected')) {
      return AppTheme.error;
    } else if (feedback.contains('callback') || feedback.contains('later')) {
      return AppTheme.warning;
    }
    return AppTheme.gray;
  }

  @override
  Widget build(BuildContext context) {
    final name = call['driver_name']?.toString() ?? 'Unknown';
    final mobile = call['user_number']?.toString() ?? '';
    final notesRaw = call['notes']?.toString() ?? '';
    final feedback = call['feedback']?.toString() ?? 'No feedback';
    final remarks = call['remarks']?.toString() ?? '';
    final tcFor = call['tc_for']?.toString() ?? '';
    final createdAt = call['created_at']?.toString() ?? '';
    
    // Extract source and role from notes field
    String source = 'Social Media';
    String role = '';
    if (notesRaw.isNotEmpty) {
      final parts = notesRaw.split('|');
      for (var part in parts) {
        if (part.contains('Source:')) {
          source = part.replaceAll('Source:', '').trim();
        }
        if (part.contains('Role:')) {
          role = part.replaceAll('Role:', '').trim();
        }
      }
    }

    DateTime? callDate;
    try {
      callDate = DateTime.parse(createdAt);
    } catch (e) {
      callDate = null;
    }

    final sourceColor = _sourceColor();
    final feedbackColor = _feedbackColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: sourceColor.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: sourceColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mobile,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sourceColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sourceIcon(), size: 12, color: sourceColor),
                      const SizedBox(width: 4),
                      Text(
                        source,
                        style: AppTheme.bodySmall.copyWith(
                          color: sourceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feedbackColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.feedback_outlined, size: 16, color: feedbackColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback,
                      style: AppTheme.bodyLarge.copyWith(
                        color: feedbackColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined, size: 16, color: AppTheme.gray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remarks,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (call['manual_call_recording_url']?.toString().isNotEmpty == true) ...[
              AudioPlayerWidget(
                recordingUrl: call['manual_call_recording_url'].toString(),
                label: 'Social Media Call Recording',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (callDate != null)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppTheme.gray),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(callDate),
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray),
                      ),
                    ],
                  ),
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: role.toLowerCase() == 'driver'
                          ? AppTheme.primaryBlue.withOpacity(0.12)
                          : AppTheme.accentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: role.toLowerCase() == 'driver'
                            ? AppTheme.primaryBlue
                            : AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (tcFor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: AppTheme.gray),
                  const SizedBox(width: 4),
                  Text(
                    'TC For: $tcFor',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.gray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppTheme.accentPurple));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.gray),
            const SizedBox(height: 16),
            Text(
              'No call history yet',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your social media call history will appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
}
