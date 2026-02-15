class CwsiService {
  // CWSI Baseline constants
  // These values are based on standard agricultural CWSI calculations
  // for Andrographis (King of Bitters) / general crop applications

  // Lower Limit (LL): Non-water-stressed baseline (leaf cooler than air)
  // When leaf temp - air temp ≤ this value, plant has plenty of water
  static const double _llBaseline = -2.0; // Tc - Ta when well-watered

  // Upper Limit (UL): Fully water-stressed baseline (leaf warmer than air)
  // When leaf temp - air temp ≥ this value, plant is severely stressed
  static const double _ulBaseline = 5.0; // Tc - Ta when severely stressed

  /// Calculates the Crop Water Stress Index (CWSI)
  /// Formula: CWSI = ((Tc - Ta) - LL) / (UL - LL)
  /// donde:
  /// - Tc = Leaf/Canopy Temperature (ตัน้อย)
  /// - Ta = Air Temperature (อุณหภูมิอากาศ)
  /// - LL = Lower Limit baseline (-2.0)
  /// - UL = Upper Limit baseline (5.0)
  ///
  /// Returns: CWSI value between 0.0 (no stress) and 1.0 (severe stress)
  static double calculateCWSI(double leafTemp, double airTemp) {
    print('[CWSI] Calculating: leafTemp=$leafTemp, airTemp=$airTemp');

    if (leafTemp == 0 || airTemp == 0) {
      print('[CWSI] Zero value detected, returning 0.0');
      return 0.0;
    }

    // Calculate temperature difference (Tc - Ta)
    double tempDiff = leafTemp - airTemp;
    print('[CWSI] Temperature difference (Tc - Ta): $tempDiff°C');

    // Avoid division by zero
    if ((_ulBaseline - _llBaseline) == 0) {
      print('[CWSI] Baseline difference is zero, returning 0.0');
      return 0.0;
    }

    // Apply CWSI formula
    double cwsi = (tempDiff - _llBaseline) / (_ulBaseline - _llBaseline);
    print('[CWSI] Raw CWSI value: $cwsi');

    // Clamp between 0 and 1
    if (cwsi < 0) cwsi = 0.0;
    if (cwsi > 1) cwsi = 1.0;

    double finalCwsi = double.parse(cwsi.toStringAsFixed(2));
    print('[CWSI] [OK] Final CWSI: $finalCwsi');
    return finalCwsi;
  }

  /// Get water stress status based on CWSI value
  /// - 0.0 - 0.2: No stress (healthy)
  /// - 0.2 - 0.5: Mild stress (monitor irrigation)
  /// - 0.5 - 0.8: Moderate stress (consider irrigation)
  /// - 0.8 - 1.0: Severe stress (urgent irrigation needed)
  static String getCwsiStatus(double cwsi) {
    if (cwsi < 0.2) {
      return 'ปกติ'; // Normal
    } else if (cwsi < 0.5) {
      return 'ปานกลาง'; // Moderate
    } else {
      return 'เครียด'; // Stressed
    }
  }

  /// Get detailed status description
  static String getCwsiStatusDetail(double cwsi) {
    if (cwsi < 0.2) {
      return 'ไม่มีภาวะเครียด - พืชได้รับน้ำเพียงพอ';
    } else if (cwsi < 0.4) {
      return 'เครียดเล็กน้อย - ตรวจสอบความชื้นดิน';
    } else if (cwsi < 0.6) {
      return 'เครียดปานกลาง - พิจารณาการให้น้ำ';
    } else if (cwsi < 0.8) {
      return 'เครียดมาก - ให้น้ำโดยด่วน';
    } else {
      return 'เครียดรุนแรง - จำเป็นต้องให้น้ำเร่งด่วน';
    }
  }

  /// Function to get forecast CWSI for the next 3 days
  /// Uses current sensor data and applies temperature trend simulation
  /// [currentLeafTemp] = Current leaf/canopy temperature
  /// [currentAirTemp] = Current air temperature
  static List<Map<String, dynamic>> getForecastCWSI({
    required double currentLeafTemp,
    required double currentAirTemp,
  }) {
    print('[CWSI Forecast] Generating 3-day forecast');
    List<Map<String, dynamic>> forecast = [];

    // Day 1: +1°C air, +0.5°C leaf (slight warming)
    double day1AirTemp = currentAirTemp + 1.0;
    double day1LeafTemp = currentLeafTemp + 0.5;
    double day1Cwsi = calculateCWSI(day1LeafTemp, day1AirTemp);

    forecast.add({
      'day': 'อีก 1 วัน',
      'cwsi': day1Cwsi,
      'status': getCwsiStatus(day1Cwsi),
      'airTemp': day1AirTemp,
      'leafTemp': day1LeafTemp,
    });

    // Day 2: +1.5°C air, +1°C leaf (more warming)
    double day2AirTemp = currentAirTemp + 1.5;
    double day2LeafTemp = currentLeafTemp + 1.0;
    double day2Cwsi = calculateCWSI(day2LeafTemp, day2AirTemp);

    forecast.add({
      'day': 'อีก 2 วัน',
      'cwsi': day2Cwsi,
      'status': getCwsiStatus(day2Cwsi),
      'airTemp': day2AirTemp,
      'leafTemp': day2LeafTemp,
    });

    // Day 3: +2°C air, +1.5°C leaf (significant warming)
    double day3AirTemp = currentAirTemp + 2.0;
    double day3LeafTemp = currentLeafTemp + 1.5;
    double day3Cwsi = calculateCWSI(day3LeafTemp, day3AirTemp);

    forecast.add({
      'day': 'อีก 3 วัน',
      'cwsi': day3Cwsi,
      'status': getCwsiStatus(day3Cwsi),
      'airTemp': day3AirTemp,
      'leafTemp': day3LeafTemp,
    });

    return forecast;
  }

  /// Calculate average CWSI from forecast (for 3-day summary card)
  static double getAverageForecastCWSI({
    required double currentLeafTemp,
    required double currentAirTemp,
  }) {
    final forecast = getForecastCWSI(
      currentLeafTemp: currentLeafTemp,
      currentAirTemp: currentAirTemp,
    );

    double sum = 0;
    for (var day in forecast) {
      sum += day['cwsi'] as double;
    }

    double average = sum / forecast.length;
    return double.parse(average.toStringAsFixed(2));
  }
}
