/*class Plot {
  final int? id;
  final String name;
  final String imagePath;
  final String plantType;
  final String datePlanted;
  final double leafTemp; // Last known value
  final double waterLevel; // Last known value
  final String? note;

  Plot({
    this.id,
    required this.name,
    required this.imagePath,
    required this.plantType,
    required this.datePlanted,
    this.leafTemp = 0.0,
    this.waterLevel = 0.0,
    this.note,
  });

  // Convert to Map for SQLite

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'plant_type': plantType,
      'date_planted': datePlanted,
      'leaf_temp': leafTemp,
      'water_level': waterLevel,
      'note': note,
    };
  }

  // Create from Map - Maps from database column names to model fields
  factory Plot.fromMap(Map<String, dynamic> map) {
    print('[Plot.fromMap] Creating plot from: ${map.toString()}');

    final plot = Plot(
      id: map['plot_id'] ?? map['id'], // Try plot_id first, then id
      name: map['plot_name'] ??
          map['name'] ??
          '', // Try plot_name first, then name
      imagePath: map['image_path'] ?? '',
      plantType: map['plant_type'] ?? '',
      datePlanted: map['planting_date'] ??
          map['date_planted'] ??
          '', // Try planting_date first, then date_planted
      leafTemp: (map['leaf_temp'] ?? 0.0) as double,
      waterLevel: (map['water_level'] ?? 0.0) as double,
      note: map['note'],
    );

    print(
        '[Plot.fromMap] Parsed: ID=${plot.id}, name=${plot.name}, leaf_temp=${plot.leafTemp}');
    return plot;
  }
}*/
class Plot {
  final int? id;
  final String name;
  final String imagePath;
  final String plantType;
  final String datePlanted;
  final double leafTemp;
  final double waterLevel;
  final String? note;
  final double latitude;
  final double longitude;

  Plot({
    this.id,
    required this.name,
    required this.imagePath,
    required this.plantType,
    required this.datePlanted,
    this.leafTemp = 0.0,
    this.waterLevel = 0.0,
    this.note,
    this.latitude = 13.7563, // Default: Bangkok
    this.longitude = 100.5018, // Default: Bangkok
  });

  // Convert to Map for SQLite / MySQL
  Map<String, dynamic> toMap() {
    // 1. แก้ไขเรื่องวันที่: ตัดเวลาและ Z ทิ้งให้เหลือแค่ YYYY-MM-DD
    String cleanDate = datePlanted;
    if (datePlanted.length > 10) {
      cleanDate = datePlanted.substring(0, 10);
    }

    return {
      'id': id,
      'plot_name': name, // ชื่อคอลัมน์ใน DB
      'image_path': imagePath,
      'plant_type': plantType,
      'planting_date':
          cleanDate, // ชื่อคอลัมน์ใน DB (ต้องส่งวันที่แบบไม่มีเวลา)
      'leaf_temp': leafTemp,
      'water_level': waterLevel,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create from Map
  factory Plot.fromMap(Map<String, dynamic> map) {
    return Plot(
      id: map['plot_id'] ?? map['id'],
      name: map['plot_name'] ?? map['name'] ?? '',
      imagePath: map['image_path'] ?? '',
      plantType: map['plant_type'] ?? '',
      // รับค่าได้ทั้ง key เก่าและใหม่
      datePlanted: map['planting_date']?.toString() ??
          map['date_planted']?.toString() ??
          '',
      // ป้องกัน Error หาก DB ส่งมาเป็น int หรือ string
      leafTemp: double.tryParse(map['leaf_temp'].toString()) ?? 0.0,
      waterLevel: double.tryParse(map['water_level'].toString()) ?? 0.0,
      note: map['note'],
      latitude:
          double.tryParse(map['latitude']?.toString() ?? '13.7563') ?? 13.7563,
      longitude: double.tryParse(map['longitude']?.toString() ?? '100.5018') ??
          100.5018,
    );
  }
}
