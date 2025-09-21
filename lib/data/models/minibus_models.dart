// lib/data/models/minibus_models.dart

class Stop {
  String name;
  int durationFromPrevious; // Bir önceki duraktan bu durağa kadar geçmesi gereken süre

  Stop({required this.name, required this.durationFromPrevious});
}

class VehicleRecord {
  String plateNumber;
  String date;
  List<String> arrivalTimes;

  VehicleRecord({
    required this.plateNumber,
    required this.date,
    required this.arrivalTimes,
  });
}

class DelayAnalysis {
  String plateNumber;
  String tripTime;
  int totalDelayMinutes;
  List<StopDelay> stopDelays;
  bool isReturn;

  DelayAnalysis({
    required this.plateNumber,
    required this.tripTime,
    required this.totalDelayMinutes,
    required this.stopDelays,
    this.isReturn = false,
  });
}

class StopDelay {
  String stopName;
  int delayMinutes;
  String expectedTime;
  String actualTime;

  StopDelay({
    required this.stopName,
    required this.delayMinutes,
    required this.expectedTime,
    required this.actualTime,
  });
}