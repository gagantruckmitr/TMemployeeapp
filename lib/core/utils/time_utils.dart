/// Time utility functions for formatting and calculations
class TimeUtils {
  /// Formats work hours from decimal (e.g., 8.43) to HH:MM:SS format
  /// Input can be a decimal string like "8.43" or null
  static String formatWorkHours(String? workHours) {
    if (workHours == null || workHours.isEmpty) {
      return '0:00:00';
    }

    try {
      final hours = double.parse(workHours);
      final totalSeconds = (hours * 3600).round();
      final h = totalSeconds ~/ 3600;
      final m = (totalSeconds % 3600) ~/ 60;
      final s = totalSeconds % 60;

      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } catch (e) {
      return '0:00:00';
    }
  }

  /// Formats a DateTime to HH:MM AM/PM format
  static String formatTimeAmPm(DateTime? dateTime) {
    if (dateTime == null) return '--:--';

    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  /// Formats a DateTime to a readable date string
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${days[dateTime.weekday - 1]}, ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// Parses a time string and returns formatted time
  static String parseAndFormatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';

    try {
      final dateTime = DateTime.parse(timeString);
      return formatTimeAmPm(dateTime);
    } catch (e) {
      return '--:--';
    }
  }

  /// Calculates duration between two DateTimes and returns formatted string
  static String calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '0:00';

    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }
}
