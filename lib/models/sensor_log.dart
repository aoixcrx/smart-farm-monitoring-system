class SensorLog {
  final int? logId;
  final int plotId;
  final double airTemp;
  final double airHumidity;
  final double leafTemp;
  final double lightLux;
  final double cwsiIndex;
  final String recordedAt;

  SensorLog({
    this.logId,
    required this.plotId,
    this.airTemp = 0.0,
    this.airHumidity = 0.0,
    this.leafTemp = 0.0,
    this.lightLux = 0.0,
    this.cwsiIndex = 0.0,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'log_id': logId,
      'plot_id': plotId,
      'air_temp': airTemp,
      'air_humidity': airHumidity,
      'leaf_temp': leafTemp,
      'light_lux': lightLux,
      'cwsi_index': cwsiIndex,
      'recorded_at': recordedAt,
    };
  }

  factory SensorLog.fromMap(Map<String, dynamic> map) {
    return SensorLog(
      logId: map['log_id'],
      plotId: map['plot_id'] ?? 0,
      airTemp: (map['air_temp'] ?? 0.0).toDouble(),
      airHumidity: (map['air_humidity'] ?? 0.0).toDouble(),
      leafTemp: (map['leaf_temp'] ?? 0.0).toDouble(),
      lightLux: (map['light_lux'] ?? 0.0).toDouble(),
      cwsiIndex: (map['cwsi_index'] ?? 0.0).toDouble(),
      recordedAt: map['recorded_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
