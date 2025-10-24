import 'package:cloud_firestore/cloud_firestore.dart';

enum SampleStatus { analyzing, completed, resultReturned }

SampleStatus statusFromString(String status) {
  switch (status) {
    case 'Đang phân tích':
      return SampleStatus.analyzing;
    case 'Hoàn thành':
    case 'Đã trả kết quả':
      return SampleStatus.completed;
    case 'Trả kết quả':
      return SampleStatus.resultReturned;
    default:
      return SampleStatus.analyzing;
  }
}

String statusToString(SampleStatus status) {
  switch (status) {
    case SampleStatus.analyzing:
      return 'Đang phân tích';
    case SampleStatus.completed:
      return 'Hoàn thành';
    case SampleStatus.resultReturned:
      return 'Trả kết quả';
  }
}

class SampleModel {
  final String id;
  final String sampleCode;
  final String customerName;
  final String sampleType;
  final String receivedDate;
  final SampleStatus status;
  final Timestamp createdAt;

  SampleModel({
    required this.id,
    required this.sampleCode,
    required this.customerName,
    required this.sampleType,
    required this.receivedDate,
    required this.status,
    required this.createdAt,
  });

  factory SampleModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SampleModel(
      id: documentId,
      sampleCode: data['sampleCode'] ?? 'N/A',
      customerName: data['customerName'] ?? 'Không rõ',
      sampleType: data['sampleType'] ?? 'Chung',
      receivedDate: data['receivedDate'] ?? 'N/A',
      status: statusFromString(data['status'] ?? 'Đang phân tích'),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sampleCode': sampleCode,
      'customerName': customerName,
      'sampleType': sampleType,
      'receivedDate': receivedDate,
      'status': statusToString(status),
      'createdAt': createdAt,
    };
  }

  SampleModel copyWith({
    String? id,
    String? sampleCode,
    String? customerName,
    String? sampleType,
    String? receivedDate,
    SampleStatus? status,
    Timestamp? createdAt,
  }) {
    return SampleModel(
      id: id ?? this.id,
      sampleCode: sampleCode ?? this.sampleCode,
      customerName: customerName ?? this.customerName,
      sampleType: sampleType ?? this.sampleType,
      receivedDate: receivedDate ?? this.receivedDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<SampleModel> mockSamples = [
    SampleModel(
      id: 'M001',
      sampleCode: 'NERD-3107-22023',
      customerName: 'Công ty one thành viên',
      sampleType: 'Nước thải',
      status: SampleStatus.analyzing,
      receivedDate: '15/07/2024',
      createdAt: Timestamp.fromDate(DateTime(2025, 10, 25)),
    ),
    SampleModel(
      id: 'M002',
      sampleCode: 'NERD-3107-22024',
      customerName: 'Tập đoàn siêu to',
      sampleType: 'Nước doanh nghiệp',
      receivedDate: '16/07/2024',
      status: SampleStatus.completed,
      createdAt: Timestamp.fromDate(DateTime(2025, 10, 24)),
    ),
    SampleModel(
      id: 'M003',
      sampleCode: 'NERD-3107-22025',
      customerName: 'Cửa hàng Ministop',
      sampleType: 'Không khí',
      receivedDate: '17/07/2024',
      status: SampleStatus.resultReturned,
      createdAt: Timestamp.fromDate(DateTime(2025, 10, 20)),
    ),
    SampleModel(
      id: 'M004',
      sampleCode: 'NERD-3107-22026',
      customerName: 'Doanh nghiệp Nước sạch',
      sampleType: 'Nước ngầm',
      receivedDate: '18/07/2024',
      status: SampleStatus.analyzing,
      createdAt: Timestamp.fromDate(DateTime(2024, 7, 18)),
    ),
  ];
}
