import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart' as io;
import '../services/database_service.dart' as io;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/theme_toggle.dart';
import 'sensor_graph_screen.dart';
import 'sensor_history_screen.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ApiService _apiService = ApiService();

  String _activeTab = 'thingspeak';
  bool _loading = false;
  Map<String, List<FlSpot>> _fileDataSets = {};
  String _currentMetric = '';
  List<FlSpot> _chartData = [];
  String _fileName = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Auto-load if needed, or wait for user
    // _fetchThingSpeak();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchThingSpeak() async {
    setState(() {
      _loading = true;
      _activeTab = 'thingspeak';
      _errorMessage = null;
      _fileName = '';
      _chartData = [];
      _fileDataSets = {};
      _currentMetric = 'Air Temperature';
    });

    try {
      // Load Data from sensor_logs table
      final dbService = io.DatabaseService();
      final logs = await dbService.getSensorLogs(limit: 50);

      if (logs.isEmpty) {
        throw Exception('No sensor data found in database.');
      }

      // Convert logs to Chart Data (Grouping by metric)
      Map<String, List<FlSpot>> newSets = {};

      final metrics = {
        'Air Temperature': 'air_temp',
        'Humidity': 'humidity',
        'Leaf Temp': 'leaf_temp',
        'Light Intensity': 'lux',
      };

      for (var entry in metrics.entries) {
        List<FlSpot> spots = [];
        for (int i = 0; i < logs.length; i++) {
          final log = logs[i];
          final val = double.tryParse(log[entry.value]?.toString() ?? '');
          if (val != null && val > 0) {
            spots.add(FlSpot((logs.length - 1 - i).toDouble(), val));
          }
        }
        if (spots.isNotEmpty) {
          newSets[entry.key] = spots;
        }
      }

      if (newSets.isEmpty)
        throw Exception('Data found but no numeric values to plot.');

      if (mounted) {
        setState(() {
          _fileDataSets = newSets;
          _currentMetric = newSets.keys.first;
          _chartData = newSets[_currentMetric]!;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Loaded ${logs.length} sensor records from database.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sync Error: $e';
          _loading = false;
        });
      }
    }
  }

  /*
  void _parseApiData(Map<String, dynamic> data) {
    // Logic to parse JSON from ThingSpeak and convert to FlSpot
  }
  */

  Future<void> _exportCSV() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch data from sensor_logs
      final dbService = io.DatabaseService();
      final logs = await dbService.getSensorLogs(limit: 100);

      if (logs.isEmpty) throw Exception('No sensor data to export');

      // 2. Convert to CSV
      List<List<dynamic>> rows = [];
      rows.add([
        'Log ID',
        'Timestamp',
        'Air Temp',
        'Humidity',
        'Leaf Temp',
        'Light (Lux)',
        'Water Level',
        'CWSI'
      ]);

      for (var log in logs) {
        rows.add([
          log['log_id'],
          log['timestamp']?.toString() ?? '',
          log['air_temp'],
          log['humidity'],
          log['leaf_temp'],
          log['lux'],
          log['water_level'],
          log['cwsi_value'],
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      // 3. Save file
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/sensor_data_export.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      setState(() {
        _loading = false;
        _fileName = 'sensor_data_export.csv';
      });

      // 4. Share/Open
      await Share.shareXFiles([XFile(path)], text: 'Smart Farm Sensor Data');
    } catch (e) {
      setState(() {
        _errorMessage = 'Export Error: $e';
        _loading = false;
      });
    }
  }

  void _parseFileData(List<List<dynamic>> rows) {
    try {
      List<String> headers = rows[0].map((e) => e.toString().trim()).toList();
      Map<String, List<FlSpot>> newSets = {};

      // Limit rows for performance if too large
      int numRows = rows.length > 100 ? 100 : rows.length;

      for (int colIndex = 0; colIndex < headers.length; colIndex++) {
        String colName = headers[colIndex];
        // Skip timestamp/date columns usually
        if (colName.toLowerCase().contains('created_at') ||
            colName.toLowerCase().contains('date')) continue;

        List<FlSpot> spots = [];
        bool isNumeric = false;

        for (int i = 1; i < numRows; i++) {
          if (colIndex >= rows[i].length) continue;
          var val = rows[i][colIndex];
          double? numVal = double.tryParse(val.toString());
          if (numVal != null) {
            spots.add(FlSpot((i - 1).toDouble(), numVal));
            isNumeric = true;
          }
        }

        if (isNumeric && spots.isNotEmpty) {
          // Rename fields for better UX if they match ThingSpeak pattern
          if (colName == 'field1') colName = 'Air Temperature';
          if (colName == 'field2') colName = 'Humidity';
          if (colName == 'field3') colName = 'Light Intensity';

          newSets[colName] = spots;
        }
      }

      if (newSets.isEmpty) throw Exception('No numeric data found');

      setState(() {
        _fileDataSets = newSets;
        _currentMetric = newSets.keys.first;
        _chartData = newSets[_currentMetric]!;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Parse error: $e';
        _loading = false;
      });
    }
  }

  void _changeMetric(String metricName) {
    setState(() {
      _currentMetric = metricName;
      _chartData = _fileDataSets[metricName]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        color: colors.background,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(colors),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(Icons.storage_rounded,
                                size: 24, color: colors.primary),
                            const SizedBox(width: 10),
                            Text('แหล่งข้อมูล',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colors.text)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Source Selection
                        Row(
                          children: [
                            Expanded(
                                child: _buildSourceCard(
                              isActive: _activeTab == 'thingspeak',
                              icon: Icons.cloud_sync,
                              title: 'Sensor',
                              //title: 'Live API',
                              subtitle: 'Sensor Data',
                              info: 'Real-time',
                              activeColors: isDark
                                  ? [const Color(0xFF065F46), colors.primary]
                                  : [
                                      const Color(0xFFD1FAE5),
                                      const Color(0xFFA7F3D0)
                                    ],
                              inactiveColors: isDark
                                  ? [Colors.white10, Colors.white10]
                                  : [
                                      const Color(0xFFF9FAFB),
                                      const Color(0xFFF3F4F6)
                                    ],
                              iconBg: colors.primary,
                              textColor: const Color(0xFF065F46),
                              onTap: () {
                                // Navigate to sensor graph screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SensorGraphScreen(),
                                  ),
                                );
                              },
                              isDark: isDark, colors: colors,
                            )),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildSourceCard(
                              isActive: _activeTab == 'excel',
                              icon: Icons.file_download,
                              title: 'Export Data',
                              subtitle: 'Download CSV',
                              info: 'Save File',
                              activeColors: isDark
                                  ? [
                                      const Color(0xFF064E3B),
                                      const Color(0xFF10B981)
                                    ]
                                  : [
                                      const Color(0xFFD1FAE5),
                                      const Color(0xFF6EE7B7)
                                    ],
                              inactiveColors: isDark
                                  ? [Colors.white10, Colors.white10]
                                  : [
                                      const Color(0xFFF9FAFB),
                                      const Color(0xFFF3F4F6)
                                    ],
                              iconBg: const Color(0xFF10B981),
                              textColor: const Color(0xFF064E3B),
                              onTap: () {
                                // Navigate to sensor history screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SensorHistoryScreen(),
                                  ),
                                );
                              },
                              isDark: isDark,
                              colors: colors,
                            )),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Button
                        _activeTab == 'thingspeak'
                            ? _buildActionButton(
                                'Sync Data',
                                Icons.sync,
                                [colors.primary, const Color(0xFF059669)],
                                _fetchThingSpeak)
                            : _buildActionButton(
                                'ดาวน์โหลดข้อมูลออกเป็น CSV',
                                Icons.download,
                                [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669)
                                ],
                                _exportCSV),

                        // File Badge
                        if (_fileName.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.insert_drive_file,
                                  size: 16, color: colors.primary),
                              const SizedBox(width: 8),
                              Text(_fileName,
                                  style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold))
                            ]),
                          ),
                          if (_fileDataSets.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _fileDataSets.keys
                                    .map((key) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            label: Text(key),
                                            selected: _currentMetric == key,
                                            onSelected: (val) {
                                              if (val) _changeMetric(key);
                                            },
                                            selectedColor:
                                                colors.accent.withOpacity(0.2),
                                            backgroundColor: colors.cardBg,
                                            labelStyle: TextStyle(
                                                color: _currentMetric == key
                                                    ? colors.accent
                                                    : colors.textLight),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ]
                        ],

                        const SizedBox(height: 24),

                        // Chart Area
                        if (_loading)
                          Center(
                              child: CircularProgressIndicator(
                                  color: colors.primary))
                        else if (_errorMessage != null)
                          Center(
                              child: Text(_errorMessage!,
                                  style: TextStyle(color: colors.error)))
                        else if (_chartData.isNotEmpty)
                          _buildChartSection(isDark, colors)
                        else
                          Center(
                              child: Text('กรุณาเลือกแหล่งข้อมูล',
                                  style: TextStyle(color: colors.textLight))),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub Widgets ---

  Widget _buildSliverAppBar(AppColors colors) {
    return SliverAppBar(
      expandedHeight: 220,
      backgroundColor: Colors.transparent,
      floating: false,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Header Image
            Image.asset(
              'assets/tree1.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors.headerGradient,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.analytics,
                                size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 8),
                            Text(
                              'DATA ANALYTICS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ThemeToggle(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Data',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2)),
                  const SizedBox(height: 4),
                  const Text('INSIGHTS & VISUALIZATION',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(
      {required bool isActive,
      required IconData icon,
      required String title,
      required String subtitle,
      required String info,
      required List<Color> activeColors,
      required List<Color> inactiveColors,
      required Color iconBg,
      required Color textColor,
      required VoidCallback onTap,
      required bool isDark,
      required AppColors colors}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive ? activeColors : inactiveColors),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 10)
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: isActive
                          ? iconBg
                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                      shape: BoxShape.circle),
                  child: Icon(icon,
                      size: 28,
                      color: isActive ? Colors.white : colors.textLight)),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? (isDark ? colors.primary : textColor)
                          : colors.text)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? (isDark
                              ? Colors.white70
                              : textColor.withOpacity(0.8))
                          : colors.textLight),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(info,
                  style: TextStyle(
                      fontSize: 10,
                      color: isActive
                          ? (isDark
                              ? Colors.white54
                              : textColor.withOpacity(0.6))
                          : colors.textLight.withOpacity(0.7))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon,
      List<Color> gradientColors, VoidCallback onTap) {
    return Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          boxShadow: [
            BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                offset: const Offset(0, 4),
                blurRadius: 8)
          ]),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700))
              ]))),
    );
  }

  Widget _buildChartSection(bool isDark, AppColors colors) {
    if (_chartData.isEmpty) return const SizedBox();

    double maxY = _chartData.map((e) => e.y).reduce(max) + 2;
    double minY = _chartData.map((e) => e.y).reduce(min) - 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          Text('Data Visualization: $_currentMetric',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colors.text)),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 10, color: colors.textLight)))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 10, color: colors.textLight)))),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData,
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true, color: colors.primary.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
