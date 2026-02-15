import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_log.dart';
import '../services/database_service.dart';

class SensorHistoryScreen extends StatefulWidget {
  const SensorHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<SensorLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Use the original getSensorLogs method instead of getSensorLogsAsObjects
      // to avoid the mysql1 driver RangeError issue
      final rawData = await _dbService.getSensorLogs(limit: 100);

      // Convert raw maps to SensorLog objects
      List<SensorLog> logs = rawData.map((map) {
        return SensorLog.fromMap(map);
      }).toList();

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
      print('[SensorHistoryScreen] [OK] Loaded ${_logs.length} records');
    } catch (e) {
      print('[SensorHistoryScreen] [ERROR] Error loading history: $e');
      setState(() {
        _logs = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Text('Timestamp')),
                        DataColumn(label: Text('CWSI')),
                        DataColumn(label: Text('Leaf Temp\n(°C)')),
                        DataColumn(label: Text('Air Temp\n(°C)')),
                        DataColumn(label: Text('Humidity\n(%)')),
                        DataColumn(label: Text('Light\n(lux)')),
                      ],
                      rows: _logs.map((log) {
                        DateTime timestamp = DateTime.parse(log.recordedAt);
                        return DataRow(cells: [
                          DataCell(Text(
                            DateFormat('MM/dd HH:mm:ss').format(timestamp),
                            style: const TextStyle(fontSize: 11),
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: log.cwsiIndex > 0.5
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                log.cwsiIndex.toStringAsFixed(2),
                                style: TextStyle(
                                  color: log.cwsiIndex > 0.5
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(
                            log.leafTemp.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          )),
                          DataCell(Text(
                            log.airTemp.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          )),
                          DataCell(Text(
                            '${log.airHumidity.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 11),
                          )),
                          DataCell(Text(
                            log.lightLux.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 11),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.download),
        label: const Text('Export CSV'),
      ),
    );
  }
}
