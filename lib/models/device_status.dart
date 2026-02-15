class DeviceStatus {
  final int? deviceId;
  final String deviceName;
  final bool isActive;
  final String updatedAt;

  DeviceStatus({
    this.deviceId,
    required this.deviceName,
    required this.isActive,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'is_active': isActive ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  factory DeviceStatus.fromMap(Map<String, dynamic> map) {
    return DeviceStatus(
      deviceId: map['device_id'],
      deviceName: map['device_name'] ?? '',
      isActive: (map['is_active'] ?? 0) == 1,
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
