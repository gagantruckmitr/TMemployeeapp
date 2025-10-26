/// State Code Mapper
/// Extracts state from TM ID and maps to full state name
class StateCodeMapper {
  // Map of state codes to full state names
  static const Map<String, String> _stateMap = {
    'AN': 'Andaman and Nicobar',
    'AP': 'Andhra Pradesh',
    'AR': 'Arunachal Pradesh',
    'AS': 'Assam',
    'BR': 'Bihar',
    'CH': 'Chandigarh',
    'CG': 'Chhattisgarh',
    'DN': 'Dadra and Nagar Haveli',
    'DD': 'Daman and Diu',
    'DL': 'Delhi',
    'GA': 'Goa',
    'GJ': 'Gujarat',
    'HR': 'Haryana',
    'HP': 'Himachal Pradesh',
    'JK': 'Jammu and Kashmir',
    'JH': 'Jharkhand',
    'KA': 'Karnataka',
    'KL': 'Kerala',
    'LD': 'Lakshadweep',
    'MP': 'Madhya Pradesh',
    'MH': 'Maharashtra',
    'MN': 'Manipur',
    'ML': 'Meghalaya',
    'MZ': 'Mizoram',
    'NL': 'Nagaland',
    'OR': 'Odisha',
    'PY': 'Puducherry',
    'PB': 'Punjab',
    'RJ': 'Rajasthan',
    'SK': 'Sikkim',
    'TN': 'Tamil Nadu',
    'TS': 'Telangana',
    'TR': 'Tripura',
    'UP': 'Uttar Pradesh',
    'UK': 'Uttarakhand',
    'WB': 'West Bengal',
  };

  /// Extract state code from TM ID
  /// Example: TM2503HRTP00002 -> HR
  static String? extractStateCode(String tmId) {
    if (tmId.isEmpty || !tmId.startsWith('TM')) return null;
    
    // Pattern: TM + 4 digits + 2 letter state code + rest
    // Example: TM2503HRTP00002
    final regex = RegExp(r'TM\d{4}([A-Z]{2})');
    final match = regex.firstMatch(tmId);
    
    return match?.group(1);
  }

  /// Get full state name from TM ID
  /// Example: TM2503HRTP00002 -> Haryana
  static String getStateName(String tmId) {
    final stateCode = extractStateCode(tmId);
    if (stateCode == null) return 'Unknown';
    
    return _stateMap[stateCode] ?? stateCode;
  }

  /// Get state code and name
  /// Example: TM2503HRTP00002 -> {code: 'HR', name: 'Haryana'}
  static Map<String, String> getStateInfo(String tmId) {
    final stateCode = extractStateCode(tmId);
    if (stateCode == null) {
      return {'code': '', 'name': 'Unknown'};
    }
    
    return {
      'code': stateCode,
      'name': _stateMap[stateCode] ?? stateCode,
    };
  }

  /// Check if state code is valid
  static bool isValidStateCode(String code) {
    return _stateMap.containsKey(code);
  }

  /// Get all states
  static Map<String, String> getAllStates() {
    return Map.from(_stateMap);
  }
}
