import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_log.dart';
import '../services/database_service.dart';

class SensorGraphScreen extends StatefulWidget {
  const SensorGraphScreen({Key? key}) : super(key: key);

  @override
  State<SensorGraphScreen> createState() => _SensorGraphScreenState();
}

class _SensorGraphScreenState extends State<SensorGraphScreen> {
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
      final rawData = await _dbService.getSensorLogs(limit: 30);

      // Convert raw maps to SensorLog objects
      List<SensorLog> logs = rawData.map((map) {
        return SensorLog.fromMap(map);
      }).toList();

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
      print('[SensorGraphScreen] [OK] Loaded ${_logs.length} data points');
    } catch (e) {
      print('[SensorGraphScreen] [ERROR] Error loading data: $e');
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
        title: const Text('Sensor Trends'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // CWSI Graph
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CWSI Index Trend',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index >= 0 &&
                                              index < _logs.length) {
                                            if (index % 5 == 0) {
                                              return Text(
                                                DateFormat('HH:mm').format(
                                                  DateTime.parse(
                                                      _logs[index].recordedAt),
                                                ),
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              );
                                            }
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _logs.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value.cwsiIndex,
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.red,
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Temperature Graph
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Temperature Comparison',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          if (index >= 0 &&
                                              index < _logs.length) {
                                            if (index % 5 == 0) {
                                              return Text(
                                                DateFormat('HH:mm').format(
                                                  DateTime.parse(
                                                      _logs[index].recordedAt),
                                                ),
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              );
                                            }
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    // Air Temp (Blue)
                                    LineChartBarData(
                                      spots: _logs.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value.airTemp,
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 2,
                                      dotData: FlDotData(show: false),
                                    ),
                                    // Leaf Temp (Green)
                                    LineChartBarData(
                                      spots: _logs.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value.leafTemp,
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.green,
                                      barWidth: 2,
                                      dotData: FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Legend
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.circle,
                                      color: Colors.blue, size: 12),
                                  const SizedBox(width: 4),
                                  const Text('Air Temp'),
                                  const SizedBox(width: 20),
                                  const Icon(Icons.circle,
                                      color: Colors.green, size: 12),
                                  const SizedBox(width: 4),
                                  const Text('Leaf Temp'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
