/// Philippine Standard Time is UTC+8 throughout the year.
class PhilippineTime {
  static const offset = Duration(hours: 8);

  /// For reading calendar fields only; keep the original instant for comparisons.
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  static DateTime fromWallClock(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
  ]) => DateTime.utc(year, month, day, hour, minute).subtract(offset);
}
