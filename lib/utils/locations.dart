import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// City is handled via free-text input in forms; this model is no longer needed.

class District {
  final String district;
  final List<String> blocks;
  District({required this.district, this.blocks = const []});
}

class StateEntry {
  final String state;
  final List<District> districts;
  StateEntry({required this.state, required this.districts});

  factory StateEntry.fromMap(Map<String, dynamic> m) {
    var dlist = (m['districts'] as List<dynamic>)
        .map((d) => District(
              district: d['district'] as String,
              blocks: List<String>.from(d['block'] as List? ?? []),
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

  /// Helper: blocks for a given state and district (or empty list)
  List<String> blocksForDistrict(String stateName, String districtName) {
    final s = states.firstWhere(
      (e) => e.state == stateName,
      orElse: () => StateEntry(state: '', districts: []),
    );
    final d = s.districts.firstWhere(
      (x) => x.district == districtName,
      orElse: () => District(district: '', blocks: []),
    );
    return d.blocks;
  }

  /// City is now a free-text input. These methods are no longer needed.
  @Deprecated('Cities are now handled as free-text input. Remove this method.')
  List<String> citiesFor(String stateName, String districtName) {
    // Return empty list since cities are no longer in the data structure
    return [];
  }

  /// City validation is no longer possible since cities are not in the dataset.
  @Deprecated('Cities are now free-text input. Remove this method.')
  bool isKnownCity(String stateName, String districtName, String cityName) {
    // Always return true since we can't validate against a dataset
    return true;
  }
}

/// Load from asset
Future<Locations> loadLocationsFromAsset() async {
  final jsonStr = await rootBundle.loadString('assets/data/locations_nested.json');
  final map = json.decode(jsonStr) as Map<String, dynamic>;
  return Locations.fromMap(map);
}