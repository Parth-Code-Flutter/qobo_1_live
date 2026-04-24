import 'package:intl/intl.dart';

extension AppDateTimeExtension on DateTime {
  static String convertServerDateToDDMMYYYY(String date) {
    try {
      DateTime tempDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(date);
      String displayDate = DateFormat("dd MMM, yyyy").format(tempDate);
      return displayDate;
    } catch (e) {
      return date;
    }
  }

  static String convertServerDateToYY(String date) {
    try {
      DateTime tempDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(date);
      String displayDate = DateFormat("yy").format(tempDate);
      return displayDate;
    } catch (e) {
      return date;
    }
  }

  static String convertServerDateToYYYY(String date) {
    try {
      DateTime tempDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(date);
      String displayDate = DateFormat("yyyy").format(tempDate);
      return displayDate;
    } catch (e) {
      return date;
    }
  }

  static String convertDDMMYYYY(String date) {
    try {
      DateTime tempDate = DateFormat("yyyy-MM-dd").parse(date);
      String displayDate = DateFormat("dd/MM/yyyy").format(tempDate);
      return displayDate;
    } catch (e) {
      return date;
    }
  }

  String get dateWithDDMMYYYY {
    try {
      // DateTime tempDate = DateFormat("yyyy-MM-dd").format(this);
      String displayDate = DateFormat("dd/MM/yyyy").format(this);
      return displayDate;
    } catch (e) {
      return this.toString();
    }
  }

  /// converts this `dateTime` to `String` to show in UI
  String get dateWithYear {
    final converted = DateFormat('dd MMM, yyyy').format(this);
    return converted;
  }

  /// converts this `dateTime` to `String` to show in UI
  String get dateWithoutYear {
    final converted = DateFormat('dd MMM').format(this);
    return converted;
  }

  String get dateForDB {
    final converted = DateFormat('yyyy-MM-dd').format(this);
    return converted;
  }

  /// calculates age from this `dateTime`
  int get calculateAge {
    final currentDate = DateTime.now();
    var age = currentDate.year - year;
    final month1 = currentDate.month;
    final month2 = month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      final day1 = currentDate.day;
      final day2 = day;
      if (day2 > day1) {
        age--;
      }
    }
    return age + 1;
  }

  /// converts this `dateTime` to Verbose DateTime Representation
  String get verboseDateTimeRepresentation {
    final now = DateTime.now();
    final justNow = now.subtract(const Duration(minutes: 1));
    final localDateTime = toLocal();

    if (!localDateTime.difference(justNow).isNegative) {
      return 'Just Now';
    }

    final roughTimeString = DateFormat('jm').format(this);

    if (localDateTime.day == now.day &&
        localDateTime.month == now.month &&
        localDateTime.year == now.year) {
      return roughTimeString;
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (localDateTime.day == yesterday.day &&
        localDateTime.month == now.month &&
        localDateTime.year == now.year) {
      return 'Yesterday';
    }

    if (now.difference(localDateTime).inDays < 4) {
      final weekday = DateFormat('EEEE').format(localDateTime);

      return '$weekday, $roughTimeString';
    }

    return '${DateFormat('d/M/y').format(this)}, $roughTimeString';
  }

  /// converts this `dateTime` to Verbose Date Representation
  String get verboseDate {
    final now = DateTime.now();
    final localDateTime = toLocal();

    if (localDateTime.day == now.day &&
        localDateTime.month == now.month &&
        localDateTime.year == now.year) {
      return 'Today';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (localDateTime.day == yesterday.day &&
        localDateTime.month == now.month &&
        localDateTime.year == now.year) {
      return 'Yesterday';
    }

    if (now.difference(localDateTime).inDays < 4) {
      final weekday = DateFormat('EEEE').format(localDateTime);

      return weekday;
    }

    return DateFormat('yMd').format(this);
  }

  String get timeString {
    return DateFormat('hh:mm aa').format(this);
  }

  static String to24hours(int hours, int minutes) {
    final hour = hours.toString().padLeft(2, "0");
    final min = minutes.toString().padLeft(2, "0");
    return "$hour:$min:00";
  }

  static DateTime parseTimeString(String timeString) {
    final timeComponents = timeString.split(' ');
    final time = timeComponents[0];
    final period = timeComponents[1];
    final hourMinute = time.split(':');
    var hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);

    // Adjust hour for PM times
    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour,
      minute,
    );
  }

  /// Convert any date string to dd/mm/yyyy format for display
  static String toDisplayFormat(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      DateTime? date;
      
      // First, check if it's the API format with GMT+0530 and India Standard Time
      if (dateString.contains("GMT+0530") && dateString.contains("India Standard Time")) {
        date = parseApiFormat(dateString);
      }
      // Try parsing different date formats
      else if (dateString.contains('T') || dateString.contains('Z')) {
        // ISO format
        date = DateTime.tryParse(dateString);
      } else if (dateString.contains('/')) {
        // Already in dd/mm/yyyy format
        List<String> parts = dateString.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          date = DateTime(year, month, day);
        }
      } else {
        // Try other formats (including the API format without explicit check)
        date = parseApiFormat(dateString) ?? DateTime.tryParse(dateString);
      }
      
      if (date != null) {
        return DateFormat("dd/MM/yyyy").format(date);
      }
      
      return dateString; // Return original if parsing fails
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  /// Convert dd/mm/yyyy format to API format: "Fri Aug 01 2025 00:00:00 GMT+0530 (India Standard Time)"
  static String toApiFormat(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      // Parse dd/mm/yyyy format
      List<String> parts = dateString.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        
        DateTime date = DateTime(year, month, day);
        
        // Format as "Fri Aug 01 2025 00:00:00 GMT+0530 (India Standard Time)"
        String formattedDate = DateFormat("EEE MMM dd yyyy HH:mm:ss 'GMT'Z", 'en_US').format(date);
        
        // Add timezone offset for India (GMT+0530)
        String timezoneOffset = "+0530";
        String indiaTimezone = "(India Standard Time)";
        
        return formattedDate.replaceAll("GMT", "GMT$timezoneOffset") + " $indiaTimezone";
      }
      
      return dateString; // Return original if parsing fails
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  /// Convert API format to DateTime object
  static DateTime? parseApiFormat(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      // Handle the specific API format: "Fri Aug 01 2025 00:00:00 GMT+0530 (India Standard Time)"
      // Also handles truncated versions like "Tue Dec 16 2025 00:00:00 GMT+0530 (India Standard T"
      if (dateString.contains("GMT+0530")) {
        // Extract the date part before GMT
        String datePart = dateString.split("GMT")[0].trim();
        try {
          return DateFormat("EEE MMM dd yyyy HH:mm:ss", 'en_US').parse(datePart);
        } catch (e) {
          // If parsing fails, try without seconds
          try {
            return DateFormat("EEE MMM dd yyyy HH:mm", 'en_US').parse(datePart);
          } catch (e2) {
            // If that also fails, try a more flexible approach
            return DateTime.tryParse(datePart);
          }
        }
      }
      
      // Try parsing as ISO format
      return DateTime.tryParse(dateString);
    } catch (e) {
      return null;
    }
  }
}
