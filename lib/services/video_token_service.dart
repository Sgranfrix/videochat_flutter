import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoTokenService {
  static const String _backendUrl = 'http://localhost:8082';

  /// Ottiene il token RTC dal backend
  Future<String> getRtcToken(String channelName, String userId) async {
    final uri = Uri.parse('$_backendUrl/rtc-token')
        .replace(queryParameters: {
      'channelName': channelName,
      'userId': userId,
    });

    print('📡 Chiamata GET $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          throw Exception('Token non ricevuto dal backend');
        }

        print('🔑 Token RTC ricevuto: $token');
        return token;
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore durante il recupero del token: $e');
      rethrow;
    }
  }
}

