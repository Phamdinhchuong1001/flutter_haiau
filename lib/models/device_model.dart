import 'package:cloud_firestore/cloud_firestore.dart';

// Trạng thái thiết bị
enum DeviceStatus {
  active,
  broken,
  calibrating,
  outOfService,
}

// Convert ENUM -> String
String statusToString(DeviceStatus status) {
  switch (status) {
    case DeviceStatus.active:
      return "Đang hoạt động";
    case DeviceStatus.broken:
      return "Hư hỏng";
    case DeviceStatus.calibrating:
      return "Đang hiệu chuẩn";
    case DeviceStatus.outOfService:
      return "Ngừng sử dụng";
  }
}

// Convert String -> ENUM
DeviceStatus statusFromString(String status) {
  switch (status) {
    case "Đang hoạt động":
      return DeviceStatus.active;
    case "Hư hỏng":
      return DeviceStatus.broken;
    case "Đang hiệu chuẩn":
      return DeviceStatus.calibrating;
    case "Ngừng sử dụng":
      return DeviceStatus.outOfService;
    default:
      return DeviceStatus.active;
  }
}

// Device Model
class DeviceModel {
  final String id;
  final String deviceCode;
  final String name;
  final String model;
  final String manufacturer;

  // 🔥 CHỈNH SỬA: purchaseDate phải là Timestamp
  final Timestamp purchaseDate;

  // 🔥 calibrationCycle lưu dạng String vẫn OK
  final String calibrationCycle;

  final DeviceStatus status;
  final Timestamp createdAt;

  DeviceModel({
  required this.id,
  required this.deviceCode,
  required this.name,
  required this.model,
  required this.manufacturer,
  required this.purchaseDate,      
  required this.calibrationCycle,
  required this.status,
  required this.createdAt,
});

  // Convert API / Firestore data -> Model
  factory DeviceModel.fromMap(Map<String, dynamic> data, String id) {
    return DeviceModel(
      id: id,
      deviceCode: data['deviceCode'] ?? '',
      name: data['name'] ?? '',
      model: data['model'] ?? '',
      manufacturer: data['manufacturer'] ?? '',

      // 🔥 FIX CHÍNH: parse purchaseDate (timestamp)
      purchaseDate: data['purchaseDate'] is Timestamp
        ? data['purchaseDate']
        : Timestamp.now(),

      calibrationCycle: data['calibrationCycle'] ?? '',

      status: statusFromString(data['status'] ?? "Đang hoạt động"),

      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt']
          : Timestamp.now(),
    );
  }

  DeviceModel copyWith({
    String? deviceCode,
    String? name,
    String? model,
    String? manufacturer,
    Timestamp? purchaseDate,
    String? calibrationCycle,
    DeviceStatus? status,
  }) {
    return DeviceModel(
      id: id,
      deviceCode: deviceCode ?? this.deviceCode,
      name: name ?? this.name,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      calibrationCycle: calibrationCycle ?? this.calibrationCycle,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
