import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../providers/theme_provider.dart';
import '../services/weather_service.dart';
import '../services/hybrid_database_service.dart';
import '../services/cwsi_service.dart';
import '../models/plot.dart';
import '../models/sensor_log.dart';
import '../widgets/theme_toggle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final HybridDatabaseService _db = HybridDatabaseService();
  late MapController _mapController;

  bool _isLoading = true;
  Timer? _timer;

  double _temp = 0; // Air Temp
  double _humidity = 0;
  double _lux = 0;
  double _leafTemp = 0; // Leaf Surface Temperature
  double _cwsiValue = 0.0; // CWSI calculated value
  String _address = 'กำลังระบุตำแหน่ง...';

  LatLng? _currentLatLng;
  List<Plot> _plots = [];
  List<Map<String, dynamic>> _forecastCwsi = [];
  Map<int, SensorLog> _latestLogsPerPlot =
      {}; // Latest sensor log for each plot

  @override
  void initState() {
    super.initState();
    _mapController = MapController(); // Initialize MapController
    _db.initialize(); // Initialize hybrid database
    _init();
    _fetchCurrentLocation(); // Fetch GPS on startup
    // Start 5-second polling for real-time data
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchRealTimeData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadPlots();
    await _loadLatestSensorLogsPerPlot();
    await _loadLocationAndWeather();
    _loadForecast();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadForecast() {
    // Calculate forecast using first plot's sensor log data if available
    if (_plots.isNotEmpty) {
      final plot = _plots.first;
      // Use latest sensor log leaf temp for first plot, fallback to plot.leafTemp
      final leafTemp = _latestLogsPerPlot[plot.id]?.leafTemp ?? plot.leafTemp;
      _forecastCwsi = CwsiService.getForecastCWSI(
        currentLeafTemp: leafTemp > 0 ? leafTemp : 28.0,
        currentAirTemp: _temp,
      );
    } else {
      // Fallback to current temps
      _forecastCwsi = CwsiService.getForecastCWSI(
        currentLeafTemp: 28.0,
        currentAirTemp: _temp > 0 ? _temp : 26.0,
      );
    }
  }

  Future<void> _loadPlots() async {
    try {
      print('[HomeScreen] ===== LOADING PLOTS START =====');
      print('[HomeScreen] Loading plots from database...');
      _plots = await _db.getAllPlots();
      print('[HomeScreen] Loaded ${_plots.length} plots');
      for (var p in _plots) {
        print(
            '[HomeScreen]   - ID:${p.id} | Name:"${p.name}" | leaf_temp:${p.leafTemp} | water:${p.waterLevel} | plant:"${p.plantType}"');
      }
      print('[HomeScreen] ===== LOADING PLOTS END =====');
      if (mounted) setState(() {});
    } catch (e) {
      print('[HomeScreen] [ERROR] Error loading plots: $e');
      print('[HomeScreen] Stack trace: ${e.toString()}');
    }
  }

  /// Fetch current GPS location based on device location
  /// This will be used as default for greenhouses without GPS
  Future<void> _fetchCurrentLocation() async {
    try {
      print('[HomeScreen] Fetching current GPS location...');

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[HomeScreen] ⚠️ Location services are disabled');
        return;
      }

      // Check and request location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('[HomeScreen] ⚠️ Location permission denied');
          return;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      print(
          '[HomeScreen] ✅ Current location: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentLatLng = location;
        });

        // Move map to current location
        _mapController.move(location, 15.0);
      }

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          if (mounted) {
            setState(() {
              _address =
                  '${p.subAdministrativeArea ?? ''}, ${p.administrativeArea ?? ''}';
            });
          }
        }
      } catch (e) {
        print('[HomeScreen] Error getting address: $e');
      }
    } catch (e) {
      print('[HomeScreen] [ERROR] Error getting location: $e');
    }
  }

  Future<void> _loadLatestSensorLogsPerPlot() async {
    try {
      print('[HomeScreen] Loading latest sensor logs per plot...');
      final logs = await _db.getLatestLogsPerPlot();
      if (mounted) {
        setState(() {
          _latestLogsPerPlot = logs;
        });
      }
      print('[HomeScreen] [OK] Loaded sensor logs for ${logs.length} plots');
      for (var entry in logs.entries) {
        print(
            '[HomeScreen]   - Plot ${entry.key}: leaf_temp=${entry.value.leafTemp}°C from log_id=${entry.value.logId}');
      }
    } catch (e) {
      print('[HomeScreen] ⚠ Error loading latest logs per plot: $e');
    }
  }

  Future<void> _fetchRealTimeData() async {
    // Fetch latest environment data from sensor_logs
    final envData = await _db.getEnvironmentData();
    if (mounted) {
      setState(() {
        _temp = envData['air_temp'] ?? _temp;
        _humidity = envData['humidity'] ?? _humidity;
        _lux = envData['lux'] ?? _lux;
        _leafTemp = envData['leaf_temp'] ?? _leafTemp;

        // Calculate CWSI using leaf temp from MySQL and air temp from sensor
        _cwsiValue = CwsiService.calculateCWSI(_leafTemp, _temp);
      });
    }

    // Persist CWSI and leaf temp to database for all plots
    if (_plots.isNotEmpty && _leafTemp > 0) {
      for (var plot in _plots) {
        await _db.updatePlotSensorData(plot.id!, _leafTemp, _cwsiValue);
      }
    }

    // Also reload plots to get latest leaf temp / water level if they change dynamically
    await _loadPlots();

    // 🔒 Reload latest sensor logs for each plot
    await _loadLatestSensorLogsPerPlot();

    // Reload forecast with updated data
    _loadForecast();
  }

  Future<void> _loadLocationAndWeather() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentLatLng = LatLng(pos.latitude, pos.longitude);

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _address =
            '${p.subAdministrativeArea ?? ''}, ${p.administrativeArea ?? ''}';
      }

      // Initial weather fetch (fallback if no sensor data)
      final result = await _weatherService.getWeatherByLocation(
        pos.latitude,
        pos.longitude,
      );

      if (result.success && result.data != null) {
        if (_temp == 0) _temp = result.data!.temperature;
        if (_humidity == 0) _humidity = result.data!.humidity;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = theme.colors;
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Force dark bg for this design
      body: CustomScrollView(
        slivers: [
          /// ================= HEADER =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/tree1.png',
                      fit: BoxFit.cover, alignment: Alignment.topCenter),
                  Container(
                    color: Colors.black
                        .withOpacity(0.4), // Overlay for text readability
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(
                              0xFF0F172A), // Dark Blue/Black fade at bottom
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.energy_savings_leaf,
                                      size: 16, color: Color(0xFFF59E0B)),
                                  SizedBox(width: 8),
                                  Text(
                                    'SMART FARMING',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const ThemeToggle(),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Hydroponic',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'INTELLIGENT FARM MONITOR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ================= BODY =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === CWSI Forecast Header ===
                  Row(children: [
                    Icon(Icons.insights,
                        color: const Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('คาดการณ์ความเครียดล่วงหน้า',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                            Text('พยากรณ์ค่า CWSI ล่วงหน้า 3 วัน',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white54),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                          ]),
                    )
                  ]),
                  const SizedBox(height: 16),

                  // === CWSI Cards (Horizontal Scroll if needed, or row) ===
                  SizedBox(
                    height: 210, // Increased to fix overflow
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _plots.isNotEmpty
                            ? _plots.length
                            : 1, // Show at least dummy if no plots
                        itemBuilder: (context, index) {
                          if (_plots.isEmpty) {
                            // Calculate average CWSI for demo
                            final avgCwsi = CwsiService.getAverageForecastCWSI(
                              currentLeafTemp: 28.0,
                              currentAirTemp: _temp > 0 ? _temp : 26.0,
                            );
                            final status = CwsiService.getCwsiStatus(avgCwsi);

                            return Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                margin: const EdgeInsets.only(right: 12),
                                child: _buildPredictionCard(
                                    Plot(
                                        name: 'Demo Plot',
                                        imagePath: '',
                                        plantType: '',
                                        datePlanted: ''),
                                    {
                                      'cwsi': avgCwsi,
                                      'status': status,
                                      'day': ''
                                    },
                                    index));
                          }

                          final plot = _plots[index];

                          // Calculate average CWSI for this specific plot using its latest sensor log
                          final leafTemp =
                              _latestLogsPerPlot[plot.id]?.leafTemp ??
                                  plot.leafTemp;
                          final avgCwsi = CwsiService.getAverageForecastCWSI(
                            currentLeafTemp: leafTemp > 0 ? leafTemp : _temp,
                            currentAirTemp: _temp,
                          );
                          final status = CwsiService.getCwsiStatus(avgCwsi);

                          return Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              margin: const EdgeInsets.only(right: 12),
                              child: _buildPredictionCard(plot,
                                  {'cwsi': avgCwsi, 'status': status}, index));
                        }),
                  ),

                  const SizedBox(height: 24),

                  // === CWSI Status Section (Grid) ===
                  const Text('สถานะความเครียด (CWSI)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
                  const Text('ดัชนีความเครียดของพืชจากการขาดน้ำ',
                      style: TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Calculate real CWSI for current plots
                      if (_plots.isNotEmpty) ...[
                        Expanded(
                            child: _buildCurrentStatusCard(_plots[0], _temp)),
                        const SizedBox(width: 12),
                        if (_plots.length > 1)
                          Expanded(
                              child: _buildCurrentStatusCard(_plots[1], _temp))
                        else
                          const Spacer(),
                      ] else
                        const Text('ยังไม่มีข้อมูลโรงเรือน',
                            style: TextStyle(color: Colors.white54))
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === Environment Section ===
                  Row(children: [
                    Icon(Icons.thermostat,
                        color: const Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('สภาพแวดล้อมโดยรวม',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                            Text(
                                'ข้อมูลความชื้น ความเข้มแสง และตำแหน่งโรงเรือน',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white54),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                          ]),
                    )
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _envCard(
                              'อุณหภูมิอากาศ',
                              _temp.toStringAsFixed(1),
                              '°C',
                              Icons.thermostat,
                              const Color(0xFFEF4444))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _envCard(
                              'ความชื้นสัมพัทธ์',
                              _humidity.toStringAsFixed(1),
                              '%',
                              Icons.water_drop,
                              const Color(0xFF3B82F6))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _envCard(
                              'อุณหภูมิใบพืช',
                              _leafTemp.toStringAsFixed(1),
                              '°C',
                              Icons.eco,
                              const Color(0xFF10B981))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _envCard(
                              'ความเข้มแสง',
                              _lux.toStringAsFixed(0),
                              'Lux',
                              Icons.wb_sunny,
                              const Color(0xFFF59E0B))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Map
                  _mapCard(),
                  const SizedBox(height: 24),

                  // Plots Management List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(children: [
                          const Icon(Icons.grass,
                              color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'โรงเรือนทั้งหมด (${_plots.length})', // Dynamic count
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                          ),
                        ]),
                      ),
                      // Add Button
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._plots.map((plot) => _plotRowCard(plot)),

                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final r = await context.push('/edit_plot');
                      if (r == true) {
                        await _loadPlots();
                        setState(() {});
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFF059669),
                            style: BorderStyle.solid,
                            width: 2), // Dashed border simulated
                      ),
                      child: const Center(
                          child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text('เพิ่มโรงเรือน',
                              style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.bold))
                        ],
                      )),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CARDS =================

  Widget _buildPredictionCard(
      Plot plot, Map<String, dynamic> forecast, int index) {
    Color cardColor = index % 2 == 0
        ? const Color(0xFF064E3B)
        : const Color(0xFF1E3A8A); // Green / Blue

    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
                colors: [cardColor, cardColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_florist,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plot.name.isEmpty ? 'โรงเรือน' : plot.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(
                            left: 28.0), // Indent to align with text above
                        child: Text('สรุปสภาพความเครียด (CWSI)',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.insights, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('FORECAST',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))
                  ]),
                )
              ]),
          const Spacer(),
          Center(
              child: Column(children: [
            Text('อีก 3 วัน',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('ค่าเฉลี่ย CWSI',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
            Text(forecast['cwsi'].toString(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
          ])),
          const Spacer(),
          Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.circle, color: Colors.amber, size: 12),
                SizedBox(width: 8),
                Text(forecast['status'],
                    style: TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold))
              ]))
        ]));
  }

  Widget _buildCurrentStatusCard(Plot plot, double ta) {
    // Calculate real CWSI using latest sensor log leaf temp
    final leafTemp = _latestLogsPerPlot[plot.id]?.leafTemp ?? plot.leafTemp;
    double cwsi = CwsiService.calculateCWSI(leafTemp > 0 ? leafTemp : ta, ta);

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B), // Dark green bg
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.green, // Checkmark bg
                  shape: BoxShape.circle),
              child: Icon(Icons.check, color: Colors.white, size: 20)),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('CWSI : $cwsi',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      overflow: TextOverflow.ellipsis)),
              SizedBox(height: 4),
              Text('ไม่มีภาวะเครียด',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              Text('${plot.name} CWSI:\n0.00',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ]),
          )
        ]));
  }

  Widget _envCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapCard() {
    // Build markers for all greenhouses
    List<Marker> markers = [];

    // Add current location marker
    if (_currentLatLng != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: _currentLatLng!,
          child: const Icon(
            Icons.location_on,
            size: 36,
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    // Add markers for each greenhouse
    for (var plot in _plots) {
      if (plot.latitude > 0 && plot.longitude > 0) {
        markers.add(
          Marker(
            width: 120,
            height: 60,
            point: LatLng(plot.latitude, plot.longitude),
            child: GestureDetector(
              onTap: () {
                // Show greenhouse details when tapped
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${plot.name}\nLat: ${plot.latitude.toStringAsFixed(4)}, Lon: ${plot.longitude.toStringAsFixed(4)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        plot.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      '🌱${_latestLogsPerPlot[plot.id]?.leafTemp.toStringAsFixed(1) ?? (plot.leafTemp > 0 ? plot.leafTemp.toStringAsFixed(1) : '0.0')}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ?? LatLng(8.6433, 99.8966),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // IMPORTANT: Fix for "Access blocked" error
                // osm requires User-Agent header to be set properly
                userAgentPackageName: 'com.example.smart_farm_flutter',
                maxZoom: 18.0,
                minZoom: 1.0,
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
        ),
        // Overlay with Location Name
        Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(Icons.location_on, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ])))
      ]),
    );
  }

  Widget _plotRowCard(Plot plot) {
    // Use latest sensor log leaf temp for this specific plot
    final sensorLogLeafTemp = _latestLogsPerPlot[plot.id]?.leafTemp ?? 0.0;
    final displayLeafTemp = sensorLogLeafTemp > 0
        ? sensorLogLeafTemp
        : (plot.leafTemp > 0 ? plot.leafTemp : 25.6);
    final displayWaterLevel =
        plot.waterLevel > 0 ? plot.waterLevel : 2.0; // Mock: 2cm

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_florist, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plot.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      Text('ข้อมูลอุณหภูมิผิวใบและระดับน้ำ',
                          style: TextStyle(fontSize: 10, color: Colors.white54),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ]),
              ),
              InkWell(
                  onTap: () async {
                    print('[HomeScreen] Opening edit plot for: ${plot.name}');
                    final r = await context.push('/edit_plot', extra: plot);
                    print('[HomeScreen] Edit plot returned: $r');
                    if (r == true) {
                      print('[HomeScreen] Reloading plots...');
                      await _loadPlots();
                      setState(() {});
                      print('[HomeScreen] Plots reloaded');
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: Icon(Icons.edit, size: 16, color: Colors.blue))),
              SizedBox(width: 8),
              InkWell(
                  onTap: () => _confirmDelete(plot.id!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: Icon(Icons.delete, size: 16, color: Colors.red))),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _miniValue(
                    'อุณหภูมิผิวใบ',
                    displayLeafTemp.toStringAsFixed(1),
                    '°C',
                    Icons.thermostat)),
            Container(width: 1, height: 40, color: Colors.white10),
            Expanded(
                child: _miniValue(
                    'ระดับน้ำในโรงเรือน',
                    displayWaterLevel.toStringAsFixed(1),
                    'cm',
                    Icons.water_drop)),
          ])
        ],
      ),
    );
  }

  Widget _miniValue(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.white54),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(width: 4),
          Text(unit, style: TextStyle(fontSize: 12, color: Colors.white54)),
        ])
      ],
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('ลบแปลง', style: TextStyle(color: Colors.white)),
        content: const Text('ต้องการลบแปลงนี้หรือไม่',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _db.deletePlot(id);
              await _loadPlots();
              setState(() {});
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
