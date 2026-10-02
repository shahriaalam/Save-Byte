/// Location constants for Bangladesh with focus on Dhaka.
abstract final class LocationConstants {
  /// Default active division
  static const String defaultDivision = 'Dhaka';

  /// Bangladesh Divisions
  static const List<String> divisions = [
    'Dhaka',
    'Chattogram',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
  ];

  /// Comprehensive list of major areas in Dhaka
  static const List<String> dhakaAreas = [
    'Dhanmondi',
    'Gulshan',
    'Banani',
    'Mirpur',
    'Uttara',
    'Mohammadpur',
    'Badda',
    'Motijheel',
    'Khilgaon',
    'Old Dhaka',
    'Bashundhara R/A',
    'Tejgaon',
    'Mohakhali',
    'Malibagh',
    'Rampura',
    'Lalmatia',
    'Baridhara',
    'Shahbagh',
    'Elephant Road',
    'Cantonment',
    'Khilkhet',
    'Agargaon',
    'Shyamoli',
    'Basabo',
    'Keraniganj',
    'Savar',
    'Other',
  ];

  /// Returns supported areas for a given division.
  static List<String> getAreasForDivision(String? division) {
    if (division == null || division.isEmpty || division.toLowerCase() == 'dhaka') {
      return dhakaAreas;
    }
    return const ['City Center', 'Sadar', 'Other'];
  }
}
