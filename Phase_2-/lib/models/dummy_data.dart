// Dummy data for Phase 2 screens
// This file provides sample data for screens that haven't been connected to the API yet

class DummyData {
  // Driver data for smart calling
  static final List<Map<String, dynamic>> drivers = [
    {
      'id': '1',
      'name': 'Rajesh Kumar',
      'phone': '9876543210',
      'location': 'Mumbai, Maharashtra',
      'experience': '5 years',
      'vehicleType': 'Heavy Truck',
      'licenseType': 'Commercial',
      'status': 'Available',
      'rating': 4.5,
    },
    {
      'id': '2',
      'name': 'Amit Singh',
      'phone': '9876543211',
      'location': 'Delhi, Delhi',
      'experience': '3 years',
      'vehicleType': 'Medium Truck',
      'licenseType': 'Commercial',
      'status': 'Available',
      'rating': 4.2,
    },
    {
      'id': '3',
      'name': 'Suresh Patel',
      'phone': '9876543212',
      'location': 'Ahmedabad, Gujarat',
      'experience': '7 years',
      'vehicleType': 'Heavy Truck',
      'licenseType': 'Commercial',
      'status': 'Busy',
      'rating': 4.8,
    },
  ];

  // Transporter data for smart calling
  static final List<Map<String, dynamic>> transporters = [
    {
      'id': '1',
      'name': 'ABC Transport Co.',
      'phone': '9876543220',
      'location': 'Mumbai, Maharashtra',
      'jobTitle': 'Heavy Truck Driver Required',
      'salary': '₹25,000 - ₹30,000',
      'vehicleType': 'Heavy Truck',
      'route': 'Mumbai to Delhi',
      'postedDate': '2024-01-15',
    },
    {
      'id': '2',
      'name': 'XYZ Logistics',
      'phone': '9876543221',
      'location': 'Delhi, Delhi',
      'jobTitle': 'Medium Truck Driver Needed',
      'salary': '₹20,000 - ₹25,000',

      'vehicleType': 'Medium Truck',
      'route': 'Delhi to Jaipur',
      'postedDate': '2024-01-16',
    },
  ];

  // Match suggestions for matchmaking
  static final List<Map<String, dynamic>> matchSuggestions = [
    {
      'id': '1',
      'driverName': 'Rajesh Kumar',
      'driverPhone': '9876543210',
      'driverLocation': 'Mumbai, Maharashtra',
      'driverExperience': '5 years',
      'transporterName': 'ABC Transport Co.',
      'transporterPhone': '9876543220',
      'jobTitle': 'Heavy Truck Driver Required',
      'salary': '₹25,000 - ₹30,000',
      'route': 'Mumbai to Delhi',
      'matchScore': 95,
    },
    {
      'id': '2',
      'driverName': 'Amit Singh',
      'driverPhone': '9876543211',
      'driverLocation': 'Delhi, Delhi',
      'driverExperience': '3 years',
      'transporterName': 'XYZ Logistics',
      'transporterPhone': '9876543221',
      'jobTitle': 'Medium Truck Driver Needed',
      'salary': '₹20,000 - ₹25,000',
      'route': 'Delhi to Jaipur',
      'matchScore': 88,
    },
    {
      'id': '3',
      'driverName': 'Suresh Patel',
      'driverPhone': '9876543212',
      'driverLocation': 'Ahmedabad, Gujarat',
      'driverExperience': '7 years',
      'transporterName': 'PQR Transport',
      'transporterPhone': '9876543222',
      'jobTitle': 'Experienced Heavy Truck Driver',
      'salary': '₹30,000 - ₹35,000',
      'route': 'Ahmedabad to Mumbai',
      'matchScore': 92,
    },
  ];

  // Analytics data for charts
  static final Map<String, List<Map<String, dynamic>>> analyticsData = {
    'jobPostsOverTime': [
      {'date': 'Mon', 'value': 12},
      {'date': 'Tue', 'value': 15},
      {'date': 'Wed', 'value': 18},
      {'date': 'Thu', 'value': 14},
      {'date': 'Fri', 'value': 20},
      {'date': 'Sat', 'value': 10},
      {'date': 'Sun', 'value': 8},
    ],
    'matchConversion': [
      {'status': 'Matched', 'value': 45},
      {'status': 'Pending', 'value': 30},
      {'status': 'Rejected', 'value': 15},
      {'status': 'Expired', 'value': 10},
    ],
    'callsByDay': [
      {'day': 'Mon', 'calls': 45},
      {'day': 'Tue', 'calls': 52},
      {'day': 'Wed', 'calls': 48},
      {'day': 'Thu', 'calls': 55},
      {'day': 'Fri', 'calls': 60},
      {'day': 'Sat', 'calls': 35},
      {'day': 'Sun', 'calls': 28},
    ],
  };
}
