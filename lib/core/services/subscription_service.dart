import 'dart:convert';
import 'package:http/http.dart' as http;
import 'real_auth_service.dart';
import '../../models/subscription_model.dart';
import '../config/api_config.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._internal();
  SubscriptionService._internal();

  static String get _laravelBaseUrl => 'https://${ApiConfig.domain}/api';

  /// Get subscription statistics for dashboard using Laravel API
  Future<SubscriptionStats?> getSubscriptionStats() async {
    try {
      // Fetch today's subscriptions
      final todaySubscriptions = await getSubscriptions(period: 'today');
      // Fetch all subscriptions for total
      final allSubscriptions = await getSubscriptions(period: 'all');

      double todayRevenue = 0.0;
      for (final sub in todaySubscriptions) {
        todayRevenue += sub.amount;
      }

      double totalRevenue = 0.0;
      for (final sub in allSubscriptions) {
        totalRevenue += sub.amount;
      }

      return SubscriptionStats(
        totalSubscriptions: allSubscriptions.length,
        totalRevenue: totalRevenue,
        todaySubscriptions: todaySubscriptions.length,
        todayRevenue: todayRevenue,
        weekSubscriptions: allSubscriptions.length,
        weekRevenue: totalRevenue,
        monthSubscriptions: allSubscriptions.length,
        monthRevenue: totalRevenue,
        recentSubscriptions: [],
      );
    } catch (e) {
      print('❌ Error fetching subscription stats: $e');
      return null;
    }
  }

  /// Get all subscriptions from Laravel API
  /// API: ${ApiConfig.laravelApiBase}/reports/assigned-to-wise-summary
  /// Response structure: { success: true, data: { today: {...}, yesterday: {...}, overall: {...} } }
  Future<List<TelecallerSubscription>> getSubscriptions({
    String period = 'all',
  }) async {
    try {
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        print('⚠️ Subscriptions: No user logged in');
        return [];
      }

      // Get auth token
      final token = await RealAuthService.instance.getAuthToken();
      if (token == null) {
        print('⚠️ Subscriptions: No auth token available');
        return [];
      }

      // URL without trailing slash to avoid 301 redirect
      final url = Uri.parse('$_laravelBaseUrl/telehead/reports/assigned-to-wise-summary');

      print('📋 Fetching subscriptions from Laravel API');
      print('📋 API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📋 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<TelecallerSubscription> allSubscriptions = [];
          final dataMap = data['data'] as Map<String, dynamic>;
          final userIdStr = user.id.toString();
          
          // Map period to API section
          String apiSection;
          switch (period) {
            case 'today':
              apiSection = 'today';
              break;
            case 'yesterday':
              apiSection = 'yesterday';
              break;
            case 'week':
            case 'all':
            default:
              apiSection = 'overall';
              break;
          }
          
          // Get the section data
          if (dataMap.containsKey(apiSection)) {
            final sectionData = dataMap[apiSection] as Map<String, dynamic>;
            
            // Parse subscriptions for current user only
            if (sectionData.containsKey(userIdStr)) {
              final userSubscriptions = sectionData[userIdStr] as List;
              for (final sub in userSubscriptions) {
                allSubscriptions.add(TelecallerSubscription.fromLaravelJson(sub));
              }
            }
          }

          // Sort by updated_at descending (newest first)
          allSubscriptions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          print('✅ Loaded ${allSubscriptions.length} subscriptions for user ${user.id} (period: $period)');
          return allSubscriptions;
        } else {
          print('❌ API returned success=false');
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - token may be expired');
      } else {
        print('❌ API error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ Error fetching subscriptions: $e');
      return [];
    }
  }
}
