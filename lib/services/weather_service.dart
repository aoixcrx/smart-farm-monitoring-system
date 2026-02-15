import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

/* ================= WEATHER SERVICE ================= */

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherResult> getWeatherByLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      String locationName = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName =
            '${place.locality ?? place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}'
                .trim();
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&current_weather=true'
          '&hourly=temperature_2m,relativehumidity_2m,precipitation'
          '&timezone=auto',
        ),
      );

      if (response.statusCode != 200) {
        return WeatherResult(
          success: false,
          error: 'Failed to fetch weather data',
        );
      }

      final data = json.decode(response.body);
      final currentWeather = data['current_weather'];
      final hourly = data['hourly'];

      final now = DateTime.now();
      final currentHour = now.hour;
      final times = List<String>.from(hourly['time']);
      final index =
          times.indexWhere((t) => DateTime.parse(t).hour == currentHour);

      return WeatherResult(
        success: true,
        data: WeatherData(
          temperature: (currentWeather['temperature'] ?? 0).toDouble(),
          windspeed: (currentWeather['windspeed'] ?? 0).toDouble(),
          weathercode: currentWeather['weathercode'] ?? 0,
          humidity: index >= 0
              ? (hourly['relativehumidity_2m'][index] ?? 0).toDouble()
              : 0,
          precipitation:
              index >= 0 ? (hourly['precipitation'][index] ?? 0).toDouble() : 0,
        ),
        location: LocationData(
          latitude: latitude,
          longitude: longitude,
          name: locationName,
        ),
      );
    } catch (e) {
      return WeatherResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// [OK] ใช้แสดงผลใน UI เหมือนภาพ
  String getWeatherDescription(int code) {
    const weatherCodes = {
      0: 'ท้องฟ้าแจ่มใส',
      1: 'ท้องฟ้าแจ่มใสเป็นส่วนใหญ่',
      2: 'มีเมฆบางส่วน',
      3: 'มีเมฆมาก',
      45: 'มีหมอก',
      48: 'มีหมอกแข็ง',
      51: 'มีฝนปรอยเล็กน้อย',
      53: 'มีฝนปรอยปานกลาง',
      55: 'มีฝนปรอยหนัก',
      61: 'ฝนตกเล็กน้อย',
      63: 'ฝนตกปานกลาง',
      65: 'ฝนตกหนัก',
      80: 'ฝนฟ้าคะนอง',
      95: 'พายุฝนฟ้าคะนอง',
    };

    return weatherCodes[code] ?? 'ไม่ทราบสภาพอากาศ';
  }
} // 👈❗ สำคัญมาก ต้องปิดตรงนี้ก่อน

/* ================= MODELS ================= */

class WeatherResult {
  final bool success;
  final WeatherData? data;
  final LocationData? location;
  final String? error;

  WeatherResult({
    required this.success,
    this.data,
    this.location,
    this.error,
  });
}

class WeatherData {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final double humidity;
  final double precipitation;

  WeatherData({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.humidity,
    required this.precipitation,
  });
}

class LocationData {
  final double latitude;
  final double longitude;
  final String name;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.name,
  });
}
