import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// City is handled via free-text input in forms; this model is no longer needed.

class District {
  final String district;
  final List<String> cities;
  District({required this.district, required this.cities});
}

class StateEntry {
  final String state;
  final List<District> districts;
  StateEntry({required this.state, required this.districts});

  factory StateEntry.fromMap(Map<String, dynamic> m) {
    var dlist = (m['districts'] as List<dynamic>)
        .map((d) => District(
              district: d['district'] as String,
              cities: List<String>.from(d['cities'] as List),
            ))
        .toList();
    return StateEntry(state: m['state'] as String, districts: dlist);
  }
}

class Locations {
  final List<StateEntry> states;
  Locations({required this.states});

  factory Locations.fromMap(Map<String, dynamic> m) {
    return Locations(
      states: (m['states'] as List<dynamic>)
          .map((s) => StateEntry.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Helper: list of state names
  List<String> getStateNames() => states.map((s) => s.state).toList();

  /// Helper: districts for a given state (or empty list)
  List<String> districtsForState(String stateName) {
    final s = states.firstWhere(
      (e) => e.state == stateName,
      orElse: () => StateEntry(state: '', districts: []),
    );
    return s.districts.map((d) => d.district).toList();
  }

  /// City is now a free-text input. This helper remains for optional validation or suggestions.
  @Deprecated('Use a text field for city input. For validation, see isKnownCity.')
  List<String> citiesFor(String stateName, String districtName) {
    final s = states.firstWhere(
      (e) => e.state == stateName,
      orElse: () => StateEntry(state: '', districts: []),
    );
    final d = s.districts.firstWhere(
      (x) => x.district == districtName,
      orElse: () => District(district: '', cities: []),
    );
    return d.cities;
  }

  /// Validate if a typed city exists in the dataset for the given state and district.
  bool isKnownCity(String stateName, String districtName, String cityName) {
    final s = states.firstWhere(
      (e) => e.state == stateName,
      orElse: () => StateEntry(state: '', districts: []),
    );
    final d = s.districts.firstWhere(
      (x) => x.district == districtName,
      orElse: () => District(district: '', cities: []),
    );
    return d.cities.contains(cityName);
  }
}

/// Load from asset
Future<Locations> loadLocationsFromAsset() async {
  final jsonStr = await rootBundle.loadString('assets/data/locations_nested.json');
  final map = json.decode(jsonStr) as Map<String, dynamic>;
  return Locations.fromMap(map);
}