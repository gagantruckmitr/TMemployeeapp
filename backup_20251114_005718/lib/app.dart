import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/screenshot_helper.dart';
import 'routes/app_router.dart';
import 'core/database/database_setup.dart';

class TMEmployeeApp extends StatelessWidget {
  const TMEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize database connection on app start
    _initializeDatabase();
    
  
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Screenshot(
      controller: ScreenshotHelper.controller,
      child: MaterialApp.router(
        title: 'TruckMitr Employee',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }

  void _initializeDatabase() {
    // Print database setup instructions
    DatabaseSetup.printConnectionInstructions();
    
    // Test database connection (optional - remove in production)
    DatabaseSetup.testConnection().then((success) {
      if (success) {
        print('✅ Database connected successfully');
        DatabaseSetup.printDatabaseInfo();
      } else {
        print('❌ Database connection failed');
        print('Please check your database configuration in database_config.dart');
      }
    }).catchError((error) {
      print('Database initialization error: $error');
    });
  }
}