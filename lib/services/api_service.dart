import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ThingSpeak API Config (Example)
  static const String _baseUrl = 'https://api.thingspeak.com';
  // static const String _channelId = 'YOUR_CHANNEL_ID'; 
  // static const String _readApiKey = 'YOUR_READ_API_KEY';

  Future<Map<String, dynamic>> fetchThingSpeakData(String channelId, String apiKey) async {
    try {
      final url = Uri.parse('$_baseUrl/channels/$channelId/feeds.json?api_key=$apiKey&results=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('ThingSpeak Error: $e');
      throw Exception('Failed to connect to ThingSpeak');
    }
  }

  Future<List<dynamic>> fetchThingSpeakHistory(String channelId, String readApiKey, {int results = 20}) async {
    try {
      final url = Uri.parse('$_baseUrl/channels/$channelId/feeds.json?api_key=$readApiKey&results=$results');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['feeds'] as List<dynamic>;
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      print('ThingSpeak History Error: $e');
      throw Exception('Failed to connect to ThingSpeak History');
    }
  }

  // Example for Weather or other external APIs
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    // Open-Meteo API (Free, no key)
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,relativehumidity_2m');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      throw Exception('Weather API Error: $e');
    }
  }
}
