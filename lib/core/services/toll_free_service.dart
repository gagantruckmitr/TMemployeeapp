import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TollFreeService {
  TollFreeService._();

  static final TollFreeService instance = TollFreeService._();

  Future<Map<String, dynamic>?> searchUser(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/toll_free_search_api.php',
    ).replace(
      queryParameters: {
        'query': query,
      },
    );

    try {
      final response = await http
          .get(uri)
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception('Request failed with status ${response.statusCode}');
      }

      final Map<String, dynamic> jsonBody = json.decode(response.body);

      if (jsonBody.containsKey('user') && jsonBody['user'] != null) {
        return jsonBody;
      }

      return null;
    } catch (error) {
      throw Exception('Unable to search user: $error');
    }
  }
}
