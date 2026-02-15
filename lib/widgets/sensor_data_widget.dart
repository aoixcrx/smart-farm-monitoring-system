import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sensor_service.dart';

/// Real-time sensor data display widget
class SensorDataWidget extends StatefulWidget {
  final int deviceId;
  final int refreshIntervalSeconds;

  const SensorDataWidget({
    super.key,
    this.deviceId = 1,
    this.refreshIntervalSeconds = 5,
  });

  @override
  State<SensorDataWidget> createState() => _SensorDataWidgetState();
}

class _SensorDataWidgetState extends State<SensorDataWidget> {
  late SensorService _sensorService;

  @override
  void initState() {
    super.initState();
    _sensorService = SensorService();
    _sensorService.setDeviceId(widget.deviceId);
    _sensorService.startPolling(intervalSeconds: widget.refreshIntervalSeconds);
  }

  @override
  void dispose() {
    _sensorService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sensorService,
      builder: (context, _) {
        final data = _sensorService.latestData;
        
        if (data == null) {
          return _buildLoadingState();
        }
        
        return _buildSensorGrid(data);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 12),
            Text(
              'กำลังโหลดข้อมูล sensor...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(SensorData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.sensors, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ข้อมูล Sensor แบบ Realtime',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'อัพเดททุก ${widget.refreshIntervalSeconds} วินาที',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
            const Spacer(),
            // Refresh indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync, size: 12, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sensor values grid
        Row(
          children: [
            Expanded(
              child: _sensorCard(
                'อุณหภูมิอากาศ',
                data.temperatureAir.toStringAsFixed(1),
                '°C',
                Icons.thermostat,
                const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sensorCard(
                'อุณหภูมิใบ',
                data.temperatureLeaf.toStringAsFixed(1),
                '°C',
                Icons.eco,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _sensorCard(
                'ความชื้น',
                data.humidity.toStringAsFixed(1),
                '%',
                Icons.water_drop,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sensorCard(
                'ระดับน้ำ',
                data.waterLevel.toStringAsFixed(1),
                'cm',
                Icons.waves,
                const Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _sensorCard(
                'ความเข้มแสง',
                data.lightLux.toStringAsFixed(0),
                'Lux',
                Icons.wb_sunny,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sensorCard(
                'ความชื้นดิน',
                data.soilMoisture.toStringAsFixed(1),
                '%',
                Icons.grass,
                const Color(0xFF84CC16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sensorCard(
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
