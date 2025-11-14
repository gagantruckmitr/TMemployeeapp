import 'package:mysql1/mysql1.dart';
import 'database_config.dart';
import '../../models/database_models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  MySqlConnection? _connection;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<MySqlConnection> get connection async {
    if (_connection == null) {
      await _connect();
    }
    return _connection!;
  }

  Future<void> _connect() async {
    try {
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.username,
        password: DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: DatabaseConfig.connectionTimeout,
      );

      _connection = await MySqlConnection.connect(settings);
      print('Database connected successfully');
    } catch (e) {
      print('Database connection error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
        print('Database disconnected');
      } catch (e) {
        print('Error disconnecting: $e');
      } finally {
        _connection = null;
      }
    }
  }

  // Admin authentication
  Future<Admin?> authenticateAdmin(String email, String password) async {
    try {
      final conn = await connection;
      final results = await conn.query(
        'SELECT * FROM admins WHERE email = ? AND password = ?',
        [email, password],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        return Admin.fromJson({
          'id': row['id'],
          'role': row['role'],
          'name': row['name'],
          'mobile': row['mobile'],
          'email': row['email'],
          'email_verified_at': row['email_verified_at']?.toString(),
          'password': row['password'],
          'remember_token': row['remember_token'],
          'created_at': row['created_at']?.toString(),
          'updated_at': row['updated_at']?.toString(),
        });
      }
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  // Get all telecallers (admins with role 'telecaller')
  Future<List<Admin>> getTelecallers() async {
    try {
      final conn = await connection;
      final results = await conn.query('SELECT * FROM admins WHERE role = ?', [
        'telecaller',
      ]);

      return results
          .map(
            (row) => Admin.fromJson({
              'id': row['id'],
              'role': row['role'],
              'name': row['name'],
              'mobile': row['mobile'],
              'email': row['email'],
              'email_verified_at': row['email_verified_at']?.toString(),
              'password': row['password'],
              'remember_token': row['remember_token'],
              'created_at': row['created_at']?.toString(),
              'updated_at': row['updated_at']?.toString(),
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching telecallers: $e');
      return [];
    }
  }

  // Get drivers
  Future<List<User>> getDrivers({int limit = 50, int offset = 0}) async {
    try {
      final conn = await connection;
      final results = await conn.query(
        'SELECT * FROM users WHERE role = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
        ['driver', limit, offset],
      );

      return results.map((row) => User.fromJson(_mapRowToUser(row))).toList();
    } catch (e) {
      print('Error fetching drivers: $e');
      return [];
    }
  }

  // Get transporters
  Future<List<User>> getTransporters({int limit = 50, int offset = 0}) async {
    try {
      final conn = await connection;
      final results = await conn.query(
        'SELECT * FROM users WHERE role = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
        ['transporter', limit, offset],
      );

      return results.map((row) => User.fromJson(_mapRowToUser(row))).toList();
    } catch (e) {
      print('Error fetching transporters: $e');
      return [];
    }
  }

  // Get callback requests
  Future<List<CallbackRequest>> getCallbackRequests({
    int? assignedTo,
    CallbackStatus? status,
    AppType? appType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final conn = await connection;
      String query = 'SELECT * FROM callback_requests WHERE 1=1';
      List<dynamic> params = [];

      if (assignedTo != null) {
        query += ' AND assigned_to = ?';
        params.add(assignedTo);
      }

      if (status != null) {
        query += ' AND status = ?';
        params.add(status.value);
      }

      if (appType != null) {
        query += ' AND app_type = ?';
        params.add(appType.value);
      }

      query += ' ORDER BY request_date_time DESC LIMIT ? OFFSET ?';
      params.addAll([limit, offset]);

      final results = await conn.query(query, params);

      return results
          .map(
            (row) => CallbackRequest.fromJson({
              'id': row['id'],
              'unique_id': row['unique_id'],
              'assigned_to': row['assigned_to'],
              'user_name': row['user_name'],
              'mobile_number': row['mobile_number'],
              'request_date_time': row['request_date_time']?.toString(),
              'contact_reason': row['contact_reason'],
              'app_type': row['app_type'],
              'status': row['status'],
              'notes': row['notes'],
              'created_at': row['created_at']?.toString(),
              'updated_at': row['updated_at']?.toString(),
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching callback requests: $e');
      return [];
    }
  }

  // Update callback request status
  Future<bool> updateCallbackStatus(
    int id,
    CallbackStatus status, {
    String? notes,
  }) async {
    try {
      final conn = await connection;
      await conn.query(
        'UPDATE callback_requests SET status = ?, notes = ?, updated_at = NOW() WHERE id = ?',
        [status.value, notes, id],
      );
      return true;
    } catch (e) {
      print('Error updating callback status: $e');
      return false;
    }
  }

  // Assign callback request to telecaller
  Future<bool> assignCallbackRequest(int requestId, int telecallerId) async {
    try {
      final conn = await connection;
      await conn.query(
        'UPDATE callback_requests SET assigned_to = ?, updated_at = NOW() WHERE id = ?',
        [telecallerId, requestId],
      );
      return true;
    } catch (e) {
      print('Error assigning callback request: $e');
      return false;
    }
  }

  // Add call log
  Future<bool> addCallLog({
    required int callerId,
    required int userId,
    required String callerNumber,
    required String userNumber,
    String? referenceId,
    String? apiResponse,
  }) async {
    try {
      final conn = await connection;
      await conn.query(
        'INSERT INTO call_logs (caller_id, user_id, caller_number, user_number, call_time, reference_id, api_response, created_at, updated_at) VALUES (?, ?, ?, ?, NOW(), ?, ?, NOW(), NOW())',
        [callerId, userId, callerNumber, userNumber, referenceId, apiResponse],
      );
      return true;
    } catch (e) {
      print('Error adding call log: $e');
      return false;
    }
  }

  // Get call logs for a telecaller
  Future<List<CallLog>> getCallLogs({
    int? callerId,
    int? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final conn = await connection;
      String query = 'SELECT * FROM call_logs WHERE 1=1';
      List<dynamic> params = [];

      if (callerId != null) {
        query += ' AND caller_id = ?';
        params.add(callerId);
      }

      if (userId != null) {
        query += ' AND user_id = ?';
        params.add(userId);
      }

      query += ' ORDER BY call_time DESC LIMIT ? OFFSET ?';
      params.addAll([limit, offset]);

      final results = await conn.query(query, params);

      return results
          .map(
            (row) => CallLog.fromJson({
              'id': row['id'],
              'caller_id': row['caller_id'],
              'user_id': row['user_id'],
              'caller_number': row['caller_number'],
              'user_number': row['user_number'],
              'call_time': row['call_time']?.toString(),
              'reference_id': row['reference_id'],
              'api_response': row['api_response'],
              'created_at': row['created_at']?.toString(),
              'updated_at': row['updated_at']?.toString(),
            }),
          )
          .toList();
    } catch (e) {
      print('Error fetching call logs: $e');
      return [];
    }
  }

  // Search users by name or mobile
  Future<List<User>> searchUsers(String query, {String? role}) async {
    try {
      final conn = await connection;
      String sql = 'SELECT * FROM users WHERE (name LIKE ? OR mobile LIKE ?)';
      List<dynamic> params = ['%$query%', '%$query%'];

      if (role != null) {
        sql += ' AND role = ?';
        params.add(role);
      }

      sql += ' ORDER BY name ASC LIMIT 20';

      final results = await conn.query(sql, params);

      return results.map((row) => User.fromJson(_mapRowToUser(row))).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Helper method to map database row to User JSON
  Map<String, dynamic> _mapRowToUser(ResultRow row) {
    return {
      'id': row['id'],
      'unique_id': row['unique_id'],
      'sub_id': row['sub_id'],
      'role': row['role'],
      'name': row['name'],
      'name_eng': row['name_eng'],
      'mobile': row['mobile'],
      'otp': row['otp'],
      'email': row['email'],
      'email_verified_at': row['email_verified_at']?.toString(),
      'password': row['password'],
      'city': row['city'],
      'states': row['states'],
      'pincode': row['pincode'],
      'address': row['address'],
      'images': row['images'],
      'provider': row['provider'],
      'provider_id': row['provider_id'],
      'avatar': row['avatar'],
      'Father_Name': row['Father_Name'],
      'DOB': row['DOB'],
      'vehicle_type': row['vehicle_type'],
      'Sex': row['Sex'],
      'Marital_Status': row['Marital_Status'],
      'Highest_Education': row['Highest_Education'],
      'Driving_Experience': row['Driving_Experience'],
      'Type_of_License': row['Type_of_License'],
      'License_Number': row['License_Number'],
      'Expiry_date_of_License': row['Expiry_date_of_License'],
      'Preferred_Location': row['Preferred_Location'],
      'Current_Monthly_Income': row['Current_Monthly_Income'],
      'Expected_Monthly_Income': row['Expected_Monthly_Income'],
      'Aadhar_Number': row['Aadhar_Number'],
      'job_placement': row['job_placement'],
      'previous_employer': row['previous_employer'],
      'Aadhar_Photo': row['Aadhar_Photo'],
      'Driving_License': row['Driving_License'],
      'Transport_Name': row['Transport_Name'],
      'Year_of_Establishment': row['Year_of_Establishment'],
      'Registered_ID': row['Registered_ID'],
      'PAN_Number': row['PAN_Number'],
      'GST_Number': row['GST_Number'],
      'Fleet_Size': row['Fleet_Size'],
      'Operational_Segment': row['Operational_Segment'],
      'Average_KM': row['Average_KM'],
      'Referral_Code': row['Referral_Code'],
      'PAN_Image': row['PAN_Image'],
      'GST_Certificate': row['GST_Certificate'],
      'status': row['status'],
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    };
  }

  // Get dashboard statistics
  Future<Map<String, int>> getDashboardStats({int? telecallerId}) async {
    try {
      final conn = await connection;

      // Total drivers
      final driversResult = await conn.query(
        'SELECT COUNT(*) as count FROM users WHERE role = ?',
        ['driver'],
      );
      final totalDrivers = driversResult.first['count'] as int;

      // Total transporters
      final transportersResult = await conn.query(
        'SELECT COUNT(*) as count FROM users WHERE role = ?',
        ['transporter'],
      );
      final totalTransporters = transportersResult.first['count'] as int;

      // Callback requests stats
      String callbackQuery =
          'SELECT status, COUNT(*) as count FROM callback_requests';
      List<dynamic> params = [];

      if (telecallerId != null) {
        callbackQuery += ' WHERE assigned_to = ?';
        params.add(telecallerId);
      }

      callbackQuery += ' GROUP BY status';

      final callbackResults = await conn.query(callbackQuery, params);

      Map<String, int> callbackStats = {};
      for (var row in callbackResults) {
        callbackStats[row['status']] = row['count'] as int;
      }

      return {
        'totalDrivers': totalDrivers,
        'totalTransporters': totalTransporters,
        'pendingCallbacks': callbackStats['Pending'] ?? 0,
        'contactedCallbacks': callbackStats['Contacted'] ?? 0,
        'interestedCallbacks': callbackStats['Interested'] ?? 0,
        'notInterestedCallbacks': callbackStats['Not Interested'] ?? 0,
        'resolvedCallbacks': callbackStats['Resolved'] ?? 0,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'totalDrivers': 0,
        'totalTransporters': 0,
        'pendingCallbacks': 0,
        'contactedCallbacks': 0,
        'interestedCallbacks': 0,
        'notInterestedCallbacks': 0,
        'resolvedCallbacks': 0,
      };
    }
  }
}
