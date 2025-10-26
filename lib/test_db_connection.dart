import 'package:flutter/material.dart';
import 'core/database/database_service.dart';
import 'core/database/database_setup.dart';
import 'core/services/telecaller_service.dart';

class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({super.key});

  @override
  State<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  String _status = 'Not tested';
  bool _isLoading = false;
  List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Database Status:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testLogin,
                  child: const Text('Test Login'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _showDatabaseInfo,
                  child: const Text('Database Info'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testDataLoading,
                  child: const Text('Test Data Loading'),
                ),
                ElevatedButton(
                  onPressed: _clearLogs,
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Logs Section
            const Text(
              'Logs:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    _addLog('Starting connection test...');

    try {
      bool connected = await DatabaseSetup.testConnection();
      setState(() {
        _status = connected ? '✅ Connected Successfully!' : '❌ Connection Failed';
      });
      _addLog(connected ? 'Connection successful!' : 'Connection failed!');
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
      });
      _addLog('Connection error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing login...';
    });

    _addLog('Testing admin login...');

    try {
      // Test with default admin
      final admin = await DatabaseService.instance.authenticateAdmin('admin@gmail.com', 'admin123');
      
      if (admin != null) {
        setState(() {
          _status = '✅ Login Success: ${admin.name} (${admin.role})';
        });
        _addLog('Login successful: ${admin.name} - ${admin.email}');
      } else {
        // Try with test admin
        final testAdmin = await DatabaseService.instance.authenticateAdmin('admin@test.com', 'admin123');
        
        if (testAdmin != null) {
          setState(() {
            _status = '✅ Login Success: ${testAdmin.name} (${testAdmin.role})';
          });
          _addLog('Test login successful: ${testAdmin.name} - ${testAdmin.email}');
        } else {
          setState(() {
            _status = '❌ Login Failed: Invalid credentials';
          });
          _addLog('Login failed: Invalid credentials');
          _addLog('Try creating test admin in phpMyAdmin:');
          _addLog('INSERT INTO admins (role, name, email, password) VALUES ("admin", "Test Admin", "admin@test.com", "admin123")');
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Login Error: ${e.toString()}';
      });
      _addLog('Login error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDatabaseInfo() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting database info...';
    });

    _addLog('Fetching database information...');

    try {
      await DatabaseSetup.printDatabaseInfo();
      
      // Get additional stats
      final telecallerService = TelecallerService.instance;
      final stats = await telecallerService.getDashboardStats();
      
      setState(() {
        _status = '✅ Database info retrieved (check logs)';
      });
      
      _addLog('Dashboard Statistics:');
      stats.forEach((key, value) {
        _addLog('  $key: $value');
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Info Error: ${e.toString()}';
      });
      _addLog('Database info error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDataLoading() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing data loading...';
    });

    _addLog('Testing data loading from database...');

    try {
      final telecallerService = TelecallerService.instance;
      
      // Test loading drivers
      _addLog('Loading drivers...');
      final drivers = await telecallerService.getDrivers(limit: 5);
      _addLog('Loaded ${drivers.length} drivers');
      
      // Test loading transporters
      _addLog('Loading transporters...');
      final transporters = await telecallerService.getTransporters(limit: 5);
      _addLog('Loaded ${transporters.length} transporters');
      
      // Test loading callback requests
      _addLog('Loading callback requests...');
      final callbacks = await telecallerService.getMyCallbackRequests(limit: 5);
      _addLog('Loaded ${callbacks.length} callback requests');
      
      // Test loading telecallers
      _addLog('Loading telecallers...');
      final telecallers = await telecallerService.getTelecallers();
      _addLog('Loaded ${telecallers.length} telecallers');
      
      setState(() {
        _status = '✅ Data loading test completed';
      });
      
      _addLog('All data loading tests completed successfully!');
      
    } catch (e) {
      setState(() {
        _status = '❌ Data Loading Error: ${e.toString()}';
      });
      _addLog('Data loading error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}