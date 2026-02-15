import 'dart:async';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'database_service.dart';

class SyncService {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  // Configuration
  // Note: Channel ID from user code is 3211612
  // Note: Read Key is NOT provided. Using placeholder.
  static const String _channelId = '3211612';
  static const String _readApiKey = 'DUJ1X4OCWFMWH1U0'; // Updated from user's api.py

  Future<int> syncDataFromThingSpeak() async {
    try {
      print('Starting Sync...');
      // 1. Fetch data
      final feeds = await _apiService.fetchThingSpeakHistory(_channelId, _readApiKey, results: 50);
      print('Fetched ${feeds.length} feeds');

      int savedCount = 0;

      // 2. Iterate and Save
      for (var feed in feeds) {
        // Parse date
        final String createdAtStr = feed['created_at'];
        // ThingSpeak returns ISO 8601 like "2026-01-31T19:59:06Z"
        // MySQL DateTime format is usually 'YYYY-MM-DD HH:MM:SS'
        // But the driver might handle DateTime objects.
        DateTime createdAt = DateTime.parse(createdAtStr);

        final log = {
          'entry_id': feed['entry_id'],
          'created_at': createdAt, // Pass DateTime, driver should handle
          'field1': double.tryParse(feed['field1']?.toString() ?? '0'),
          'field2': double.tryParse(feed['field2']?.toString() ?? '0'),
          'field3': double.tryParse(feed['field3']?.toString() ?? '0'),
          'field5': double.tryParse(feed['field5']?.toString() ?? '0'),
          'field6': (int.tryParse(feed['field6']?.toString() ?? '0') ?? 0) == 1,
          'field7': (int.tryParse(feed['field7']?.toString() ?? '0') ?? 0) == 1,
        };

        int result = await _dbService.insertThingSpeakLog(log);
        savedCount += result;
      }
      
      print('Sync Complete. Saved $savedCount new records.');
      return savedCount;

    } catch (e) {
      print('Sync Error: $e');
      rethrow;
    }
  }
}
