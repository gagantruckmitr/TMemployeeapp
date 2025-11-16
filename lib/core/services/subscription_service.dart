import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'real_auth_service.dart';
import '../../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._internal();
  SubscriptionService._internal();

  /// Get subscription statistics for dashboard
  Future<SubscriptionStats?> getSubscriptionStats() async {
    try {
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        print('⚠️ Subscription Stats: No user logged in');
        return null;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_subscription_stats_api.php?user_id=${user.id}',
      );

      print('📊 Fetching subscription stats for user ID: ${user.id}');
      print('📊 API URL: $url');

      final response = await http.get(url);

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final stats = SubscriptionStats.fromJson(data['data']);
          print('✅ Subscription stats loaded: ${stats.totalSubscriptions} subscriptions');
          return stats;
        } else {
          print('❌ API returned success=false: ${data['error'] ?? 'Unknown error'}');
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching subscription stats: $e');
      return null;
    }
  }

  /// Get all subscriptions for a telecaller
  Future<List<TelecallerSubscription>> getSubscriptions({
    String period = 'all',
  }) async {
    try {
      final user = RealAuthService.instance.currentUser;
      if (user == null) {
        print('⚠️ Subscriptions: No user logged in');
        return [];
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/telecaller_subscriptions_api.php?user_id=${user.id}&period=$period',
      );

      print('📋 Fetching subscriptions for user ID: ${user.id}, period: $period');
      print('📋 API URL: $url');

      final response = await http.get(url);

      print('📋 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final subscriptions = (data['data']['subscriptions'] as List)
              .map((e) => TelecallerSubscription.fromJson(e))
              .toList();
          print('✅ Loaded ${subscriptions.length} subscriptions');
          return subscriptions;
        } else {
          print('❌ API returned success=false: ${data['error'] ?? 'Unknown error'}');
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching subscriptions: $e');
      return [];
    }
  }
}
